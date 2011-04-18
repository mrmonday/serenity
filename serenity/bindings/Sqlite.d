/**
 * Serenity Web Framework
 *
 * bindings/Sqlite.d: Wrapper around SQLite C interface
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011 Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.database.bindings.Sqlite;

extern(C):

struct sqlite3 {}
struct sqlite3_stmt {}

enum
{
    SQLITE_OK         =  0,
    SQLITE_ERROR      =  1,
    SQLITE_INTERNAL   =  2,
    SQLITE_PERM       =  3,
    SQLITE_ABORT      =  4,
    SQLITE_BUSY       =  5,
    SQLITE_LOCKED     =  6,
    SQLITE_NOMEM      =  7,
    SQLITE_READONLY   =  8,
    SQLITE_INTERRUPT  =  9,
    SQLITE_IOERR      = 10,
    SQLITE_CORRUPT    = 11,
    SQLITE_NOTFOUND   = 12,
    SQLITE_FULL       = 13,
    SQLITE_CANTOPEN   = 14,
    SQLITE_PROTOCOL   = 15,
    SQLITE_EMPTY      = 16,
    SQLITE_SCHEMA     = 17,
    SQLITE_TOOBIG     = 18,
    SQLITE_CONSTRAINT = 19,
    SQLITE_MISMATCH   = 20,
    SQLITE_MISUSE     = 21,
    SQLITE_NOLFS      = 22,
    SQLITE_AUTH       = 23,
    SQLITE_FORMAT     = 24,
    SQLITE_RANGE      = 25,
    SQLITE_NOTADB     = 26,
    SQLITE_ROW        = 100,
    SQLITE_DONE       = 101
}

int sqlite3_open(const char*, sqlite3**);
void sqlite3_close(sqlite3*);
int sqlite3_prepare_v2(sqlite3*, const char*, int, sqlite3_stmt**, const char**);
int sqlite3_finalize(sqlite3_stmt*);
int sqlite3_step(sqlite3_stmt*);

int sqlite3_bind_blob(sqlite3_stmt*, int, void*, int n, void function(void*));
int sqlite3_bind_double(sqlite3_stmt*, int, double);
int sqlite3_bind_int(sqlite3_stmt*, int, int);
int sqlite3_bind_int64(sqlite3_stmt*, int, long);
int sqlite3_bind_null(sqlite3_stmt*, int);
int sqlite3_bind_text(sqlite3_stmt*, int, const char*, int n, void function(void*));
int sqlite3_bind_text16(sqlite3_stmt*, int, const wchar*, int, void function(void*));

const(void*) sqlite3_column_blob(sqlite3_stmt*, int);
int sqlite3_column_bytes(sqlite3_stmt*, int);
int sqlite3_column_bytes16(sqlite3_stmt*, int);
double sqlite3_column_double(sqlite3_stmt*, int);
int sqlite3_column_int(sqlite3_stmt*, int);
long sqlite3_column_int64(sqlite3_stmt*, int);
const(char*) sqlite3_column_text(sqlite3_stmt*, int);
const(wchar*) sqlite3_column_text16(sqlite3_stmt*, int);
int sqlite3_column_type(sqlite3_stmt*, int);

const(char*) sqlite3_errmsg(sqlite3*);
