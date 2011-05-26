/**
 * Serenity Web Framework
 *
 * persister/Sqlite.d: Persist data to a SQLite database
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.persister.Sqlite;

import std.math : abs;
import std.typecons : Tuple, tuple;
import std.typetuple;

import serenity.database.Sqlite;
import serenity.Persister;
import serenity.SqlQuery;

/// Default database if none is provided
private SqliteDatabase defaultDatabase;
public void setDefaultDatabase(SqliteDatabase db)
{
    assert(db !is null);
    defaultDatabase = db;
}

final class SqlitePersister(T) : IPersister!(T, SqliteDatabase)
{
    /// TypeTuple of parent types
    staticMap!(.SqlitePersister, Parent!T) mParents;
    
    // TODO Should only be serenity_ for internal tables
    enum mTableName = `serenity_` ~ T.stringof;
    SqliteDatabase mDb;

    this(SqliteDatabase db=null)
    {
        foreach (parent; mParents)
        {
            parent = new typeof(parent)(db);
        }
        mDb = db is null ? defaultDatabase : db;
        assert(mDb !is null);
    }

    void initialize()
    {
        foreach (parent; mParents)
        {
            parent.initialize();
        }
        enum createStr = {
            string str = "CREATE TABLE IF NOT EXISTS `" ~ mTableName ~ "`(";
            foreach (i, field; typeof(T.tupleof))
            {
                enum fieldName = getFieldName!(i);
                static if (is(field == bool)   || is(field == byte)  ||
                        is(field == ubyte)  || is(field == short) ||
                        is(field == ushort) || is(field == int)   ||
                        is(field == uint)   || is(field == long)  ||
                        is(field == ulong)
                        )
                {
                    str ~= '`' ~ fieldName ~ "` INTEGER";
                }
                else static if (is(field == float) || is(field == double))
                {
                    str ~= '`' ~ fieldName ~ "` REAL";
                }
                else static if (is(field == string) || is(field == wstring) ||
                        is(field == DateTime))
                {
                    str ~= '`' ~ fieldName ~ "` TEXT";
                }
                else static if (is(field == ubyte[]))
                {
                    str ~= '`' ~ fieldName ~ "` BLOB";
                }
                else static if (isPointer!field && is(typeof(*field) == struct))
                {
                    enum key = SqlitePersister!(typeof(*field)).primaryKey();
                    static assert(key != null, "Referenced structs must have a field with a PRIMARY KEY constraint");
                    str ~= "FOREIGN KEY(" ~ fieldName ~ ") REFERENCES serenity_" ~ typeof(*field).stringof ~ "(" ~ key ~ ")";
                }
                else
                {
                    static assert(false, "Unsupported field type: " ~ field.stringof);
                }
                if (constrained(fieldName, NotNull))
                {
                    str ~= " NOT NULL";
                }
                if (constrained(fieldName, Unique))
                {
                    str ~= " UNIQUE";
                }
                if (constrained(fieldName, PrimaryKey))
                {
                    str ~= " PRIMARY KEY";
                    if (constrained(fieldName, AutoIncrement))
                    {
                        str ~= " AUTOINCREMENT";
                    }
                }
                if (constrained(fieldName, Check))
                {
                    assert(0);
                }
                // TODO Default value should be pulled of the struct
                /*if (constraints & Default)
                {
                    assert(0);
                }*/
                if (i < typeof(T.tupleof).length - 1)
                {
                    str ~= ", ";
                }
            }
            str ~= ");";
            return str;
        }();
        mDb.execute!T(createStr);
    }

    template RemoveIf(Constraint c)
    {
        alias RemoveIf!(c, 0, typeof(T.tupleof)) RemoveIf;
    }

    template RemoveIf(Constraint c, size_t i, U...) 
    {
        static if (U.length > 1)
        {
            alias TypeTuple!(RemoveIf!(c, U[0], getFieldName!(i)), RemoveIf!(c, i + 1, U[1..$])) RemoveIf;
        }
        else
        {
            alias RemoveIf!(c, U[0], getFieldName!(i)) RemoveIf;
        }
    }

    template RemoveIf(Constraint c, U, string str) if (!constrained(str, c))
    {
        alias U RemoveIf;
    }
    
    template RemoveIf(Constraint c, U, string str) if (constrained(str, c))
    {
        alias TypeTuple!() RemoveIf;
    }

    Tuple!(RemoveIf!(c)) removeIf(Constraint c, size_t i, size_t j, T, U)(ref T result, U args)
    {
        static if (constrained(getFieldName!(i), c))
        {
            static if (i < args.tupleof.length - 1 && j < result.tupleof.length)
            {
                removeIf!(c, i + 1, j)(result, args);
            }
        }
        else
        {
            result.field[j] = args.tupleof[i];
            static if (i < args.tupleof.length - 1 && j < result.tupleof.length)
            {
                removeIf!(c, i + 1, j + 1)(result, args);
            }
        }
        return result;
    }

    Tuple!(RemoveIf!(c)) removeIf(Constraint c, U)(U args)
    {
        typeof(return) result;
        return removeIf!(c, 0, 0)(result, args);
    }

    T opCatAssign(T row)
    {
        enum insertStr = {
            string str = "INSERT INTO `" ~ mTableName ~ "` (";
            foreach (i, field; typeof(T.tupleof))
            {
                enum fieldName = getFieldName!(i);
                if (!constrained(fieldName, AutoIncrement))
                {
                    str ~= '`' ~ fieldName ~ '`';
                    if (i < typeof(T.tupleof).length - 1)
                    {
                        str ~= ", ";
                    }
                }
            }
            str ~= ") VALUES(";
            foreach (i, field; typeof(T.tupleof))
            {
                enum fieldName = getFieldName!(i);
                if (!constrained(fieldName, AutoIncrement))
                {
                    str ~= '?';
                    if (i < typeof(T.tupleof).length - 1)
                    {
                        str ~= ", ";
                    }
                }
            }
            str ~= ");";
            return str;
        }();
        mDb.execute!T(insertStr, removeIf!AutoIncrement(row).tupleof);
        return row;
    }

    T opIndex()(ulong idx) if (primaryKey() != null)
    {
        enum selectStr = selectString() ~ " WHERE `" ~ primaryKey() ~ "` = ?;";
        return mDb.execute!T(selectStr, idx + 1)[0];
    }
    
    T opIndex()(ulong) if (primaryKey() == null)
    {
        static assert(false, T.stringof ~ " has no PRIMARY KEY field so cannot be indexed");
    }

    void opIndexAssign()(T row, ulong idx) if (primaryKey() != null)
    {
        enum updateStr = {
            string str = "UPDATE `" ~ mTableName ~ "` SET ";
            foreach (i, field; typeof(T.tupleof))
            {
                enum fieldName = getFieldName!(i);
                if (!constrained(fieldName, PrimaryKey))
                {
                    str ~= '`' ~ fieldName ~ "` = ?";
                    if (i < typeof(T.tupleof).length - 1)
                    {
                        str ~= ", ";
                    }
                }
            }
            str ~= " WHERE `" ~ primaryKey() ~ "` = ?;";
            return str;
        }();
        mDb.execute!T(updateStr, removeIf!PrimaryKey(row).tupleof, idx + 1);
    }

    void opIndexAssign()(T, ulong) if (primaryKey() == null)
    {
        static assert(false, T.stringof ~ " has no PRIMARY KEY field so cannot be indexed");
    }

    /// BUG: Should use the type of the PRIMARY KEY for the index
    T[] opSlice()(ulong a, ulong b) if (primaryKey() != null)
    {
        enum selectStr = selectString() ~ " ORDER BY `" ~ primaryKey() ~ "` ASC LIMIT ? OFFSET ?;";
        return mDb.execute!T(selectStr, b - a, a);
    }

    T[] opSlice()(ulong a, Dollar b) if (primaryKey() != null)
    {
        enum selectStr = selectString() ~ " ORDER BY `" ~ primaryKey() ~ "` ASC LIMIT ? OFFSET ?;";
        // NOTE Has to be done like this, otherwise -1 is implicitly converted to ulong - not what we want
        if (b.value == 0)
        {
            return mDb.execute!T(selectStr, -1, a);
        }
        else
        {
            return mDb.execute!T(selectStr, (a + b.value) + 1, a);
        }
    }

    T[] opSlice()(Dollar a, int b) if (primaryKey() != null)
    {
        enum selectStr = selectString() ~ " ORDER BY `" ~ primaryKey() ~ "` DESC LIMIT ? OFFSET ?;";
        if (a.value == 0)
        {
            return mDb.execute!T(selectStr, -1, b);
        }
        else
        {
            assert(0, "Unimplemented");
        }
    }

    T[] opSlice()(Dollar a, Dollar b) if (primaryKey() != null)
    {
        enum selectStr = selectString() ~ " ORDER BY `" ~ primaryKey() ~ "` DESC LIMIT ? OFFSET ?;";
        assert(b.value >= 0);
        auto res = mDb.execute!T(selectStr, abs(a.value - b.value), a.value < b.value ? a.value : b.value);
        if (b.value < a.value)
        {
            // TODO Ewwww. There has to be a nicer way of doing this.
            return res.reverse;
        }
        return res;
    }
    
    T[] opSlice(U, V)(U a, V b) if (primaryKey() == null)
    {
        pragma(msg, T.stringof ~ " has no PRIMARY KEY field so cannot be sliced");
        static assert(false, "Did you forget to use a constrain field?");
    }
    
    /**
     * Get a basic SELECT string.
     *
     * Returns:
     *     SELECT `list`, `of`, `fields` FROM `mTableName`
     */
    final static private string selectString()
    {
        string str = "SELECT ";
        foreach (i, field; typeof(T.tupleof))
        {
            enum fieldName = getFieldName!(i);
            str ~= '`' ~ fieldName ~ '`';
            if (i < typeof(T.tupleof).length - 1)
            {
                str ~= ", ";
            }
        }
        str ~= " FROM `" ~ mTableName ~ '`';
        return str;
    }

    public SqliteDatabase backend() @property
    {
        return mDb;
    }

    /**
     * Is the given field constrained
     *
     * Params:
     *     field      = Name of field
     *     constraint = Constraint to test against
     * Returns:
     *     true if the field is constrained by the given constraint
     */
    final static private bool constrained(string field, Constraint constraint)
    {
        foreach (i, v; typeof(T.tupleof))
        {
            enum fieldName = getFieldName!(i);
            static if (is(typeof({mixin(`enum _ = T.constrain_` ~ fieldName ~ `;`);}())))
            {
                mixin(`enum constraints = T.constrain_` ~ fieldName ~ `;`);
                if (fieldName == field && constraints & constraint)
                {
                    return true;
                }
            }
            else static if (fieldName == "id" && is(typeof(T.id) == ulong))
            {
                if (field == "id" && constraint & (PrimaryKey | AutoIncrement))
                {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Get a list of constrained fields
     *
     * Params:
     *     constraint = Constraint to test against
     * Returns:
     *     An array of names of fields constrained by constraint
     */
    final static private string[] constrained(Constraint constraint)
    {
        string[] fields;
        foreach (i, field; typeof(T.tupleof))
        {
            enum fieldName = getFieldName!(i);
            if (constrained(fieldName, constraint))
            {
                fields ~= fieldName;
            }
        }
        return fields is null ? [] : fields;
    }

    /**
     * Get the field name for the given member
     *
     * Params:
     *     i = Index of field to get the name of
     * Returns:
     *     The name of the field at the given index
     */
    template getFieldName(size_t i)
    {
        enum getFieldName = T.tupleof[i].stringof[T.stringof.length + 3 .. $];
    }

    /**
     * Get the name of the PRIMARY KEY field
     *
     * Returns:
     *     A string containing the name of the PRIMARY KEY field, or null if
     *     there is no PRIMARY KEY.
     */
    final static private string primaryKey()() if (constrained(PrimaryKey).length == 1)
    {
        return constrained(PrimaryKey)[0];
    }

    final static private string primaryKey()() if (constrained(PrimaryKey).length == 0)
    {
        return null;
    }

    final static private string primaryKey()() if (constrained(PrimaryKey).length > 1)
    {
        static assert(false, T.stringof ~ " has more than one PRIMARY KEY field. Did you mean to use UNIQUE?");
    }
}

unittest
{
    static struct Test
    {
        // TODO ulong id should automatically be PrimaryKey | AutoIncrement
        //enum constrain_id = PrimaryKey | AutoIncrement;
        ulong id;
        string b;

        bool opEquals(ref const Test other) const
        {
            return id == other.id && b == other.b;
        }
    }
    auto p = new SqlitePersister!Test(new SqliteDatabase(":memory:"));
    p.initialize();
    p ~= Test(4, "test1");
    p ~= Test(0, "test2");
    p ~= Test(9, "test4");
    assert(p[0] == Test(1, "test1"));
    assert(p[1] == Test(2, "test2"));
    assert(p[2] == Test(3, "test4"));
    p[2] = Test(9, "test3");
    assert(p[2] == Test(3, "test3"));
    assert(p[0..$] == [Test(1, "test1"), Test(2, "test2"), Test(3, "test3")]);
    assert(p[1..$] == [Test(2, "test2"), Test(3, "test3")]);
    assert(p[0..2] == [Test(1, "test1"), Test(2, "test2")]);
    assert(p[$-2..$] == [Test(2, "test2"), Test(3, "test3")]);
    assert(p[$-2..$-1] == [Test(2, "test2")]);
    assert(p[$..$-1] == [Test(3, "test3")]);
    assert(p[$..$-3] == [Test(3, "test3"), Test(2, "test2"), Test(1, "test1")]);
    assert(p[$..0] == [Test(3, "test3"), Test(2, "test2"), Test(1, "test1")]);
    // Unimplemented
    //assert(p[$..1] == [Test(3, "test3"), Test(2, "test2")]);
}
