/**
 * Serenity Web Framework
 *
 * bootstrap.d: Bootstrap the framework for this applications
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module bootstrap;

import serenity.Serenity;
import serenity.database.Sqlite;

import controllers;
import layouts;

int main(string[] args)
{
    /// Set logging type and level
    Log.type = Log.Type.Stderr;
    Log.level = Log.Level.Trace;

    /// Create a new SQLite Database using the given file
    auto db = new SqliteDatabase("serenity-test.db");
    scope(exit) Database.finalize();
    Database.addDatabase(db);

    /// Set up routing
    Router.addRoutes([
                        "/"[]                                    : "example/Home/Default"[],
                        "/[plugin]"                              : "[plugin]/Default/Default",
                        "/[plugin]/[controller]"                 : "[plugin]/[controller]/Default",
                        "/[plugin]/[controller]/[action]"        : "[plugin]/[controller]/[action]",
                        "/[plugin]/[controller]/[action]/[args]" : "[plugin]/[controller]/[action]/[args]"
                    ]);
    Router.errorRoute("example", "Error");

    /// Launch Serenity
    return Serenity.exec(args);
}
