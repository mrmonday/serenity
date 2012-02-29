/**
 * Serenity Web Framework
 *
 * persister/backend/Sqlite.d: Sqlite database interface
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.persister.backend.Sqlite;

import core.stdc.string : strlen;

import std.conv;
import std.datetime;
import std.exception;
import std.string;
import std.traits;
import std.typecons;
import std.typetuple;

import serenity.bindings.Sqlite;

import serenity.persister.Query;

import serenity.core.Config;
import serenity.core.Serenity;
import serenity.core.Util;

// Naive implementation that works at compile time, std.array.replace fails
string replace(string str, string[] replacements...)
in
{
    assert(replacements.length % 2 == 0);
}
body
{
    string singleReplace(string str, string from, string to)
    {
        for (size_t i = 0; i < str.length - from.length; i++)
        {
            if (str[i..i+from.length] == from)
            {
                str = str[0..i] ~ to ~ str[i+from.length..$];
            }
        }
        return str;
    }
    for (size_t i = 0; i < replacements.length; i += 2)
    {
        str = singleReplace(str, replacements[i], replacements[i+1]);
    }
    return str;
}

// TODO: Should be struct
class Sqlite
{
    private sqlite3* mDb;

    this(Config config = Config())
    {
        config = config == Config() ? .config.serenity.persister.sqlite.section("default") : config;
        check(sqlite3_open(toStringz(config["file"]), &mDb));
    }

    private alias TypeTuple!(bool, byte, ubyte, short, ushort, int, long, ulong,
                             float, double, DateTime, string, wstring, ubyte[]) SupportedTypes;
    template canPersist(T...)
    {
        static if (T.length == 1)
        {
            enum canPersist = staticIndexOf!(T[0], SupportedTypes) != -1;
        }
        else
        {
            enum canPersist = canPersist!(T[0]) && canPersist!(T[1..$]);
        }
    }

    private template fieldName(T, size_t i)
    {
        enum fieldName = T.tupleof[i].stringof[T.stringof.length + 3 .. $];
    }

    private struct SqliteQuery
    {
        string query;
        string[] columns;
    }

    private template Range(size_t a, size_t b)
    {
        static if (a == b) alias TypeTuple!() Range;
        else alias TypeTuple!(a, Range!(a+1, b)) Range;
    }

    private static size_t indexOf(T, string name)()
    {
        foreach (i; Range!(0, T.tupleof.length))
        {
            if (fieldName!(T, i) == name)
                return i;
        }
        return -1;
    }

    private template Remove(size_t i, T...)
    {
        alias TypeTuple!(T[0..i], T[i+1..$]) Remove;
    }

    static executable(T)(T row)
    {
        static if (is(IndexType!T))
        {
            Tuple!(Remove!(indexOf!(T, indexName!T)(), typeof(T.tupleof))) ret;
            //pragma(msg, typeof(T.tupleof).stringof);
            //pragma(msg, typeof(ret.field).stringof);
            foreach (i, el; row.tupleof)
            {
                static if (fieldName!(T, i) != indexName!T)
                {
                    //pragma(msg, i.stringof);
                    //pragma(msg, indexOf!(T, indexName!T)());
                    //pragma(msg, fieldName!(T, i));
                    enum idx = indexOf!(T, indexName!T)() >= i ? i : i - 1;
                    ret.field[idx] = el;
                }
            }
            return ret;
        }
        else
        {
            return tuple(row.tupleof);
        }
    }
    
    static SqliteQuery buildQuery(T)(Query!T query)
    {
        string queryStr;
        string[] columns;
        alias QueryType Qt;
        final switch(query.type)
        {
            case Qt.Invalid:
                // TODO
                break;
            case Qt.CreateTables:
                // TODO possibly a good idea to allow user defined CREATE TABLE queries
                //      to allow for better optimised tables.
                foreach (table; TablesOf!T)
                {
                    string fields;
                    foreach(i, field; typeof(table.tupleof))
                    {
                        static if (is(field == bool) || isIntegral!(field))
                        {
                            fields ~= '`' ~ fieldName!(T, i) ~ "` INTEGER";
                        }
                        else static if (is(field == float) || is(field == double))
                        {
                            // TODO What about real?
                            fields ~= '`' ~ fieldName!(T, i) ~ "` REAL";
                        }
                        else static if (is(field == string) || is(field == wstring) ||
                                is(field == DateTime))
                        {
                            fields ~= '`' ~ fieldName!(T, i) ~ "` TEXT";
                        }
                        else static if (is(field == ubyte[]))
                        {
                            // TODO dstring should probably be handled like this too
                            fields ~= '`' ~ fieldName!(T, i) ~ "` BLOB";
                        }
                        // TODO Handle foreign keys et al.
                        /*else static if (isPointer!field && is(typeof(*field) == struct))
                        {
                            enum key = SqlitePersister!(typeof(*field)).primaryKey();
                            static assert(key != null, "Referenced structs must have a field with a PRIMARY KEY constraint");
                            str ~= "FOREIGN KEY(" ~ fieldName ~ ") REFERENCES serenity_" ~ typeof(*field).stringof ~ "(" ~ key ~ ")";
                        }*/
                        else
                        {
                            static assert(false, "Unsupported field type: " ~ fieldName);
                        }
                        static if (is(IndexType!T) && fieldName!(T, i) == indexName!table)
                        {
                            fields ~= " PRIMARY KEY";
                        }
                        if (i < typeof(table.tupleof).length - 1)
                        {
                            fields ~= ", ";
                        }
                    }
                    queryStr ~= "CREATE TABLE IF NOT EXISTS `$prefix$tableName` ($fields);".replace("$prefix", query.tablePrefix,
                                                                                      "$tableName", table.stringof,
                                                                                      "$fields", fields);
                }
                break;
            case Qt.Insert:
                // TODO What about multiple tables?
                queryStr ~= "INSERT INTO `" ~ query.tablePrefix ~ T.stringof ~ "` (";
                foreach (i, field; typeof(T.tupleof))
                {
                    static if (!is(IndexType!T) || fieldName!(T, i) != indexName!T)
                    {
                        queryStr ~= '`' ~ fieldName!(T, i) ~ '`';
                        if (i < typeof(T.tupleof).length - 1)
                        {
                            queryStr ~= ", ";
                        }
                    }
                }
                queryStr ~= ") VALUES(";
                foreach (i, field; typeof(T.tupleof))
                {
                    static if (!is(IndexType!T) || fieldName!(T, i) != indexName!T)
                    {
                        queryStr ~= '?';
                        if (i < typeof(T.tupleof).length - 1)
                        {
                            queryStr ~= ", ";
                        }
                    }
                }
                queryStr ~= ");";
                break;
            case Qt.Select:
                queryStr ~= "SELECT ";
                // TODO For the ?'s below it should be possible to give constants
                // TODO Possible optimisation: don't include fields which use = in a WHERE clause
                if (auto cols = query.columns)
                {
                    columns = cols;
                    foreach (i, col; cols)
                    {
                        queryStr ~= '`' ~ col ~ '`';
                        if (i < cols.length - 1)
                        {
                            queryStr ~= ", ";
                        }
                    }
                }
                else
                {
                    foreach (i, field; typeof(T.tupleof))
                    {
                        queryStr ~= '`' ~ fieldName!(T, i) ~ '`';
                        columns ~= fieldName!(T, i);
                        if (i < typeof(T.tupleof).length - 1)
                        {
                            queryStr ~= ", ";
                        }
                    }
                }
                queryStr ~= " FROM `" ~ query.tablePrefix ~ T.stringof ~ '`';
                auto preds = query.wherePredicates;
                auto betweens = query.between;
                if (preds.length || betweens.length)
                {
                    queryStr ~= " WHERE ";
                    foreach (i, pred; preds)
                    {
                        static if (is(IndexType!T))
                            pred = pred.replace("$index", '`' ~ indexName!T ~ '`');
                        queryStr ~= pred.replace("[", "`",
                                                 "]", "`");
                        if (i < preds.length - 1 || betweens.length)
                        {
                            queryStr ~= " AND ";
                        }
                    }
                    foreach (i, col; betweens)
                    {
                        static if (is(IndexType!T))
                            col = col.replace("$index", '`' ~ indexName!T ~ '`');
                        queryStr ~= '`' ~ col ~ "` BETWEEN ?, ?";
                        if (i < betweens.length - 1)
                        {
                            queryStr ~= " AND ";
                        }
                    }
                }
                if (auto ordering = query.ordering)
                {
                    queryStr ~= " ORDER BY ";
                    foreach (column, order; ordering)
                    {
                        queryStr ~= "`" ~ column ~ "` " ~ (order == Query!T.Order.Asc ? "ASC" : "DESC");
                    }
                }
                if (query.hasLimit)
                {
                    queryStr ~= " LIMIT ?";
                }
                queryStr ~= ';';
                break;
            case Qt.Update:
                queryStr ~= "UPDATE `" ~ query.tablePrefix ~ T.stringof ~ "` SET ";
                foreach (i, field; typeof(T.tupleof))
                {
                    static if (!is(IndexType!T) || fieldName!(T, i) != indexName!T)
                    {
                        queryStr ~= '`' ~ fieldName!(T, i) ~ "` = ?";
                        if (i < typeof(T.tupleof).length - 1)
                        {
                            queryStr ~= ", ";
                        }
                    }
                }
                // TODO Maybe there should be a Query!T.isValid, UPDATE must have a WHERE
                auto preds = query.wherePredicates;
                auto betweens = query.between;
                if (preds.length || betweens.length)
                {
                    queryStr ~= " WHERE ";
                    foreach (i, pred; preds)
                    {
                        static if (is(IndexType!T))
                            pred = pred.replace("$index", '`' ~ indexName!T ~ '`');
                        queryStr ~= pred.replace("[", "`",
                                                 "]", "`");
                        if (i < preds.length - 1 || betweens.length)
                        {
                            queryStr ~= " AND ";
                        }
                    }
                    foreach (i, col; betweens)
                    {
                        static if (is(IndexType!T))
                            col = col.replace("$index", '`' ~ indexName!T ~ '`');
                        queryStr ~= '`' ~ col ~ "` BETWEEN ?, ?";
                        if (i < betweens.length - 1)
                        {
                            queryStr ~= " AND ";
                        }
                    }
                }
                queryStr ~= ';';
                break;
        }
        return SqliteQuery(queryStr, columns);
    }

    /*T[] execute(T)(string query)
    {
        import std.stdio;
        writefln("query: %s", query);
        assert(0);
    }*/

    T[] execute(T, Params...)(SqliteQuery query, Params params)
    {
        import std.stdio;
        writeln("query: ", query, "; params: ", params);
        T[] result;
        sqlite3_stmt* statement;
        // TODO Deal with tail
        char* tail;
        // TODO Clean this up
        enforce(query.query.length < int.max);
        check(sqlite3_prepare_v2(mDb, query.query.ptr, cast(int)query.query.length, &statement, &tail));
        scope (exit) check(sqlite3_finalize(statement));
        static if (params.length > 0)
        {
            static assert(params.length < int.max);
            foreach (int i, param; params)
            {
                static if(is(typeof(param) == bool) || is(typeof(param) == byte) ||
                          is(typeof(param) == ubyte) || is(typeof(param) == short) ||
                          is(typeof(param) == ushort) || is(typeof(param) == int) ||
                          is(typeof(param) == uint))
                {
                    check(sqlite3_bind_int(statement, i + 1, param));
                }
                else static if(is(typeof(param) == long) || is(typeof(param) == ulong))
                {
                    check(sqlite3_bind_int64(statement, i + 1, param));
                }
                else static if(is(typeof(param) == float) || is(typeof(param) == double))
                {
                   check(sqlite3_bind_double(statement, i + 1, param));
                }
                else static if(is(typeof(param) == DateTime))
                {
                   string isoString = param.toISOExtString();
                   check(sqlite3_bind_text(statement, i + 1, isoString.ptr, isoString.length, null));
                }
                else static if (is(typeof(param) == string))
                {
                   check(sqlite3_bind_text(statement, i + 1, param.ptr, param.length, null));
                }
                else static if (is(typeof(param) == wstring))
                {
                   check(sqlite3_bind_text16(statement, i + 1, param.ptr, param.length * 2, null));
                }
                else static if (is(typeof(param) == ubyte[]))
                {
                   assert(param.length < int.max);
                   check(sqlite3_bind_blob(statement, i + 1, param.ptr, cast(int)param.length, null));
                }
                else
                {
                    static assert(false, "Unhandled field type: " ~ typeof(param).stringof);
                }
            }
        }
        while (true)
        {
            auto st = sqlite3_step(statement);
            if (st == SQLITE_ROW)
            {
                T val;
                int col = 0;
                if (query.columns is null)
                {
                    query.columns = new string[T.tupleof.length];
                    foreach (i, type; typeof(T.tupleof))
                    {
                        query.columns[i] = T.tupleof[i].stringof[T.stringof.length+3..$];
                    }
                }
                foreach (i, type; typeof(T.tupleof))
                {
                    if (T.tupleof[i].stringof[T.stringof.length+3..$] == query.columns[col])
                    {
                        static if(is(type == bool) || is(type == byte) ||
                                  is(type == ubyte) || is(type == short) ||
                                  is(type == ushort) || is(type == int) ||
                                  is(type == uint))
                        {
                            val.tupleof[i] = cast(type)sqlite3_column_int(statement, col);
                        }
                        else static if(is(type == long) || is(type == ulong))
                        {
                           val.tupleof[i] = cast(type)sqlite3_column_int64(statement, col);
                        }
                        else static if(is(type == float) || is(type == double))
                        {
                            val.tupleof[i] = cast(type)sqlite3_column_double(statement, col);
                        }
                        else static if(is(type == string))
                        {
                            // BUG? .dup
                            val.tupleof[i] = to!string(sqlite3_column_text(statement, col));
                        }
                        else static if(is(type == wstring))
                        {
                            auto tmp = sqlite3_column_text16(statement, col); 
                            val.tupleof[i] = tmp[0..strlen(cast(char*)tmp)*3].idup;
                        }
                        else static if(is(type == ubyte[]))
                        {
                            auto blob = sqlite3_column_blob(statement, i);
                            val.tupleof[i] = cast(ubyte[])blob[0..sqlite3_column_bytes(statement, col)].dup;
                        }
                        else static if(is(type == DateTime))
                        {
                            auto time =  to!string(sqlite3_column_text(statement, col));
                            val.tupleof[i] = DateTime.fromISOExtString(time);
                        }
                        else
                        {
                            static assert(false, "Unsupported field type: " ~ type.stringof);
                        }
                        col++;
                    }

                }
                result ~= val;
            }
            else if(st == SQLITE_DONE)
            {
                break;
            }
            else
            {
                // BUG TODO Should be some other type of exception
                throw new Exception("Sqlite error: " ~ to!string(sqlite3_errmsg(mDb)));
            }
        }
        return result;
    }

    /*this(string dbName)
    {
        check(sqlite3_open(toStringz(dbName), &mDb));
    }*/

    private void check(string file=__FILE__, size_t line=__LINE__)(int errCode)
    {
        if (errCode != SQLITE_OK)
        {
            // TODO This should throw some other type of exception
            throw new Exception(file ~ ':' ~ to!string(line) ~ " SQLite error: " ~ to!string(sqlite3_errmsg(mDb)));
        }
    }

    public void finalize()
    {
        sqlite3_close(mDb);
    }
/+
    /*override protected SqlPrinter getPrinter()
    {
        return new SqlitePrinter;
    }*/
    
    public T[] execute(T, U...)(string query, U params)
    {
        Bind[] binds;
        foreach (i, param; U)
        {
            Bind b;
            b.type = TypeMap!param;
            foreach (j, v; typeof(Bind.tupleof[1..$]))
            {
                static if (is(v == param))
                {
                    b.tupleof[j+1] = params[i];
                    break;
                }
            }
            binds ~= b;
            //mixin(`b.` ~ param.stringof ~ `Val`);
           // binds ~= Bind(TypeMap!(param), params[i]);
        }
        return execute!T(query, binds);
    }
    
    public T[] execute(T, U)(string query, U[] columns...) if (is(U == string))
    {
        return execute!T(query, null, columns);
    }

    /**
     * Execute a SQL query
     *
     * TODO: Bind[] can probably be removed, the types should be known at compile time
     *
     * Params:
     *  query   = The query to execute
     *  params  = A list of parameters to bind
     *  columns = The names of the columns being operated on
     */
    public T[] execute(T)(string query, Bind[] params=null, string[] columns=null)
    {
        T[] result;
        sqlite3_stmt* statement;
        // TODO Deal with tail
        char* tail;
        // TODO Clean this up
        enforce(query.length < int.max);
        check(sqlite3_prepare_v2(mDb, toStringz(query), cast(int)query.length, &statement, &tail));
        scope (exit) check(sqlite3_finalize(statement));
        if (params.length > 0)
        {
            enforce(params.length < int.max);
            foreach (int i, param; params)
            {
                switch (param.type)
                {
                   case Type.Bool:
                        check(sqlite3_bind_int(statement, i + 1, param.boolVal));
                        break;
                   case Type.Byte:
                        check(sqlite3_bind_int(statement, i + 1, param.byteVal));
                        break;
                   case Type.Ubyte:
                        check(sqlite3_bind_int(statement, i + 1, param.ubyteVal));
                        break;
                   case Type.Short:
                        check(sqlite3_bind_int(statement, i + 1, param.shortVal));
                        break;
                   case Type.Ushort:
                        check(sqlite3_bind_int(statement, i + 1, param.ushortVal));
                        break;
                   case Type.Int:
                        //Log.error("%s : %s %s", query, i + 1, param.intVal);
                        check(sqlite3_bind_int(statement, i + 1, param.intVal));
                        break;
                   case Type.Uint:
                        check(sqlite3_bind_int(statement, i + 1, param.uintVal));
                        break;
                   case Type.Long:
                        check(sqlite3_bind_int64(statement, i + 1, param.longVal));
                        break;
                   case Type.Ulong:
                        check(sqlite3_bind_int64(statement, i + 1, param.ulongVal));
                        break;
                   case Type.Float:
                       check(sqlite3_bind_double(statement, i + 1, param.floatVal));
                       break;
                   case Type.Double:
                       check(sqlite3_bind_double(statement, i + 1, param.doubleVal));
                       break;
                   case Type.Time:
                       check(sqlite3_bind_text(statement, i + 1, toStringz(param.timeVal.toISOExtString()), -1, null));
                       break;
                   case Type.String:
                       check(sqlite3_bind_text(statement, i + 1, toStringz(param.stringVal), -1, null));
                       break;
                   case Type.Wstring:
                       if (param.wstringVal)
                       {
                           if (param.wstringVal[$-1] != '\0')
                               param.wstringVal ~= '\0';
                       }
                       check(sqlite3_bind_text16(statement, i + 1, param.wstringVal.ptr, -1, null));
                       break;
                   case Type.UbyteArr:
                       enforce(param.ubyteArrVal.length < int.max);
                       check(sqlite3_bind_blob(statement, i + 1, param.ubyteArrVal.ptr, cast(int)param.ubyteArrVal.length, null));
                       break;
                   default:
                       // BUG Should be some other type of exception
                       throw new Exception( "SQLite error: Unsupported datatype to bind" );
                }
            }
        }
        while (true)
        {
            auto st = sqlite3_step(statement);
            if (st == SQLITE_ROW)
            {
                T val;
                int col = 0;
                if (columns is null)
                {
                    columns = new string[T.tupleof.length];
                    foreach (i, type; typeof(T.tupleof))
                    {
                        columns[i] = T.tupleof[i].stringof[T.stringof.length+3..$];
                    }
                }
                foreach (i, type; typeof(T.tupleof))
                {
                    if (T.tupleof[i].stringof[T.stringof.length+3..$] == columns[col])
                    {
                        static if(is(type == bool) || is(type == byte) ||
                                  is(type == ubyte) || is(type == short) ||
                                  is(type == ushort) || is(type == int) ||
                                  is(type == uint))
                        {
                            val.tupleof[i] = cast(type)sqlite3_column_int(statement, col);
                        }
                        else static if(is(type == long) || is(type == ulong))
                        {
                           val.tupleof[i] = cast(type)sqlite3_column_int64(statement, col);
                        }
                        else static if(is(type == float) || is(type == double))
                        {
                            val.tupleof[i] = cast(type)sqlite3_column_double(statement, col);
                        }
                        else static if(is(type == string))
                        {
                            // BUG? .dup
                            val.tupleof[i] = to!string(sqlite3_column_text(statement, col));
                        }
                        else static if(is(type == wstring))
                        {
                            auto tmp = sqlite3_column_text16(statement, col); 
                            val.tupleof[i] = tmp[0..strlen(cast(char*)tmp)*3].idup;
                        }
                        else static if(is(type == ubyte[]))
                        {
                            auto blob = sqlite3_column_blob(statement, i);
                            val.tupleof[i] = cast(ubyte[])blob[0..sqlite3_column_bytes(statement, col)].dup;
                        }
                        else static if(is(type == DateTime))
                        {
                            auto time =  to!string(sqlite3_column_text(statement, col));
                            val.tupleof[i] = DateTime.fromISOExtString(time);
                        }
                        else
                        {
                            static assert(false, "Unsupported field type: " ~ type.stringof);
                        }
                        col++;
                    }

                }
                result ~= val;
            }
            else if(st == SQLITE_DONE)
            {
                break;
            }
            else
            {
                // BUG TODO Should be some other type of exception
                throw new Exception("Sqlite error: " ~ to!string(sqlite3_errmsg(mDb)));
            }
        }
        return result;
    }
    +/
}

version(none): // Remove this

unittest
{
    auto db = new SqliteDatabase(":memory:");
    scope (exit) db.finalize();
    struct Test
    {
        bool boolVal;
        byte byteVal;
        ubyte ubyteVal;
        short shortVal;
        ushort ushortVal;
        int intVal;
        uint uintVal;
        long longVal;
        ulong ulongVal;
        float floatVal;
        double doubleVal;
        //real realVal; TODO This should be supported
        string stringVal;
        wstring wstringVal;
        ubyte[] ubyteArrVal;
    }
    auto query = new Query!Test;
    query.createTable("test").bind!(Test)();
    //db.execute!(Test)(db.getPrinter().getQueryString(query), (Bind[]).init, (string[]).init);
    query = new Query!Test;
    query.insert.into("test").values(true, -1, 1, -1, 1, -1, 1, -1, 1, 3.14f, 3.14, "foo", "foo"w, "foo");
    //db.execute!(Test)(db.getPrinter().getQueryString(query), (Bind[]).init, (string[]).init);

    query = new Query!Test;
    query.select("*").from("test");
    string[] cols;
    foreach (i, v; typeof(Test.tupleof))
    {
        cols ~= Test.tupleof[i].stringof[7..$];
    }
    //auto results = db.execute!(Test)(db.getPrinter().getQueryString(query), (Bind[]).init, cols);

    /*foreach (i, result; results)
    {
        assert(i == 0); // Should only be one result
        assert(result.boolVal == true);
        assert(result.byteVal == -1);
        assert(result.ubyteVal == 1);
        assert(result.shortVal == -1);
        assert(result.ushortVal == 1);
        assert(result.intVal == -1);
        assert(result.uintVal == 1);
        assert(result.longVal == -1);
        assert(result.ulongVal == 1);
        assert(result.floatVal == 3.14f);
        assert(result.doubleVal == 3.14);
        assert(result.stringVal == "foo");
        assert(result.wstringVal == "foo"w, cast(string)result.wstringVal);
        assert(result.ubyteArrVal == cast(ubyte[])"foo");
    }*/
}
