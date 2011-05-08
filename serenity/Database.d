/**
 * Serenity Web Framework
 *
 * Database.d: Provides database functionality
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Database;

import serenity.SqlPrinter;
import serenity.SqlQuery;
import serenity.Util;

version(EnableSqliteDb)
{
    import serenity.database.Sqlite : SqliteDatabase;
}

mixin SerenityException!("Database");

abstract class Database
{
    private static Database[] mDatabases;
    private static Database mDefaultDatabase;

    abstract SqlPrinter getPrinter();
    abstract void finalize_();

    public static void addDatabase(Database db)
    {
        mDatabases ~= db;
        if (mDatabases.length == 1)
        {
            mDefaultDatabase = db;
        }
    }

    public static void setDefaultDatabase(Database db)
    {
        // TODO Check in mDatabases
        mDefaultDatabase = db;
    }

    public static Database getDefaultDatabase()
    {
        return mDefaultDatabase;
    }

    public static void finalize()
    {
        foreach (db; mDatabases)
        {
            db.finalize_();
        }
    }

    public static T[] execute(T)(SqlQuery query)
    {
        static string dbExec(string[] names...)
        {
            string ret = `default:
                            assert(false, db.classinfo.name);
                          `;
            foreach (name; names)
            {
                ret ~= `case "serenity.database.` ~ name ~ `.` ~ name ~ `Database":
                            return (cast(` ~ name ~ `Database)db)
                                    .execute!(T)(queryStr, query.getBoundParameters(), query.getColumns());
                        `;
            }
            return ret;
        }
        auto db = getDefaultDatabase();
        auto queryStr = db.getPrinter().getQueryString(query);
        // Work around the lack of templated virtual functions
        switch (db.classinfo.name)
        {
            mixin(dbExec("Sqlite"));
        }
    }
}
