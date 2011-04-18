/**
 * Serenity Web Framework
 *
 * database/Sqlite.d: Sqlite database interface
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.database.Sqlite;

import core.stdc.string : strlen;

import std.conv;
import std.string;

import serenity.bindings.Sqlite;

public import serenity.Database;
import serenity.Serenity;
import serenity.SqlitePrinter;
import serenity.Util;

class SqliteDatabase : Database
{
    private sqlite3* mDb;

    this(string dbName)
    {
        check(sqlite3_open(toStringz(dbName), &mDb));
    }

    private void check(int errCode)
    {
        if (errCode != SQLITE_OK)
        {
            throw new DatabaseException("SQLite error: " ~ to!string(sqlite3_errmsg(mDb)));
        }
    }

    public void finalize_()
    {
        sqlite3_close(mDb);
    }

    protected SqlPrinter getPrinter()
    {
        return new SqlitePrinter;
    }

    /**
     * Execute a SQL query
     *
     * Params:
     *  query   = The query to execute
     *  params  = A list of parameters to bind
     *  columns = The names of the columns being operated on
     */
    public Result!(T) execute(T)(string query, Bind[] params, string[] columns)
    {
        auto result = new Result!T;
        sqlite3_stmt* statement;
        // TODO Deal with tail
        char* tail;
        check(sqlite3_prepare_v2(mDb, toStringz(query), query.length, &statement, &tail));
        scope (exit) check(sqlite3_finalize(statement));
        if (params.length > 0)
        {
            foreach (i, param; params)
            {
                switch (param.type)
                {
                   case Type.Bool:
                        sqlite3_bind_int(statement, i, param.boolVal);
                        break;
                   case Type.Byte:
                        sqlite3_bind_int(statement, i, param.byteVal);
                        break;
                   case Type.Ubyte:
                        sqlite3_bind_int(statement, i, param.ubyteVal);
                        break;
                   case Type.Short:
                        sqlite3_bind_int(statement, i, param.shortVal);
                        break;
                   case Type.Ushort:
                        sqlite3_bind_int(statement, i, param.ushortVal);
                        break;
                   case Type.Int:
                        sqlite3_bind_int(statement, i, param.intVal);
                        break;
                   case Type.Uint:
                        sqlite3_bind_int(statement, i, param.uintVal);
                        break;
                   case Type.Long:
                        sqlite3_bind_int64(statement, i, param.longVal);
                        break;
                   case Type.Ulong:
                        sqlite3_bind_int64(statement, i, param.ulongVal);
                        break;
                   case Type.Float:
                       sqlite3_bind_double(statement, i, param.floatVal);
                       break;
                   case Type.Double:
                       sqlite3_bind_double(statement, i, param.doubleVal);
                       break;
                   case Type.Time:
                       sqlite3_bind_text(statement, i, toStringz(param.timeVal.toISOExtendedString()), -1, null);
                       break;
                   case Type.String:
                       sqlite3_bind_text(statement, i, toStringz(param.stringVal), -1, null);
                       break;
                   case Type.Wstring:
                       if (param.wstringVal)
                       {
                           if (param.wstringVal[$-1] != '\0')
                               param.wstringVal ~= '\0';
                       }
                       sqlite3_bind_text16(statement, i, param.wstringVal.ptr, -1, null);;
                       break;
                   case Type.UbyteArr:
                       sqlite3_bind_blob(statement, i, param.ubyteArrVal.ptr, param.ubyteArrVal.length, null);
                       break;
                   default:
                       throw new DatabaseException( "SQLite error: Unsupported datatype to bind" );
                }
            }
        }
        while (true)
        {
            auto st = sqlite3_step(statement);
            if (st == SQLITE_ROW)
            {
                T val;
                size_t col = 0;
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
                            val.tupleof[i] = DateTime.fromISOExtendedString(time);
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
                throw new DatabaseException("Sqlite error: " ~ to!string(sqlite3_errmsg(mDb)));
            }
        }
        return result;
    }
}

unittest
{
    auto db = new SqliteDatabase(":memory:");
    scope (exit) db.finalize_();
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
    auto query = new SqlQuery;
    query.createTable("test").bind!(Test)();
    db.execute!(Test)(db.getPrinter().getQueryString(query), (Bind[]).init, (string[]).init);
    query = new SqlQuery;
    query.insert.into("test").values(true, -1, 1, -1, 1, -1, 1, -1, 1, 3.14f, 3.14, "foo", "foo"w, "foo");
    db.execute!(Test)(db.getPrinter().getQueryString(query), (Bind[]).init, (string[]).init);

    query = new SqlQuery;
    query.select("*").from("test");
    string[] cols;
    foreach (i, v; typeof(Test.tupleof))
    {
        cols ~= Test.tupleof[i].stringof[7..$];
    }
    auto results = db.execute!(Test)(db.getPrinter().getQueryString(query), (Bind[]).init, cols);

    foreach (i, result; results)
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
    }
}
