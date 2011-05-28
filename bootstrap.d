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
import serenity.persister.backend.Sqlite;
import serenity.persister.Sqlite;

import controllers;
import layouts;

int main(string[] args)
{
    /// Set logging type and level
    Log.type = Log.Type.Stderr;
    Log.level = Log.Level.Trace;

    /// Create a new SQLite Database using the given file
    setDefaultDatabase(new SqliteDatabase("serenity-test.db"));

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
