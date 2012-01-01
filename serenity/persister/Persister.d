/**
 * Serenity Web Framework
 *
 * persister/Persister.d: Interface for persistable data
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, 2012 Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.persister.Persister;

import serenity.persister.Query;

import std.typetuple;

public import std.datetime;

version (EnableSqlitePersister)
{
    import serenity.persister.Sqlite;
    alias SqlitePersister Persister;
}
else
{
    class Persister(T)
    {
        static assert(false, "No Persister");
    }
}

/**
 * Persistance constraints
 */
enum : uint
{
    None = 0,           /// No constraints
    NotNull = 1,        /// Field must not be null
    Unique = 2,         /// Field must be unique
    PrimaryKey = 4,     /// Field must be unique, used for indexing
    Check = 8,          /// TODO: Perform a check on the given field
    AutoIncrement = 16  /// Field automatically increments
}
alias uint Constraint;

/**
 * Basic interface for persisters
 *
 * Standard array overloads should also be implemented, they may be implemented
 * as templates however, so are not included here.
 */
// DMDBug7190: T.sizeof can be removed.
interface IPersister(T, Backend) if (T.sizeof && canPersist!T && is(T == struct) && T.tupleof.length > 0)
{
    /// Intialize the persister for first time usage
    void initialize();

    /// Return the backend for direct access
    Backend backend() @property;

    /// Return a query for querying the persister
    Query!T query() @property;

}

/**
 * Represent an index for slicing and indexing.
 *
 * TODO Remove this once opDollar is implemented
 * NOTE This is implemented now, but due to regressions in dmd 2.057 cannot be used.
 */
struct Dollar
{
    int value;
    Dollar opBinary(string op)(int v) if (op == "-")
    {
        value = v;
        return this;
    }
}

/**
 * Return an instance of the Dollar struct for manipulation
 */
public Dollar __dollar()
{
    return Dollar();
}

/**
 * Return whether T is persistable
 *
 * T is persistable if it is a struct whose members are basic types,
 * arrays, structs and pointers to structs which do not reference themselves.
 */
template canPersist(T) if (is(T == struct))
{
    static if (typeof(T.tupleof).length == 0)
    {
        enum canPersist = true;
    }
    else
    {
        enum canPersist = canPersist!(T, typeof(T.tupleof));
    }
}

template canPersist(T, U...) 
{
    static if (U.length == 1)
    {
        enum canPersist = canPersist!(T, U[0]) && canPersist!(U[0], T);
    }
    else
    {
        enum canPersist = canPersist!(T, U[0]) && canPersist!(U[0], T) && canPersist!(T, U[1..$]);
    }
}

template canPersist(T, U : U*)
{
    static if (is(U == struct) && typeof(U.tupleof).length > 0)
    {
        enum canPersist = canPersist!(T, typeof(U.tupleof));
    }
    else static if (is(U == struct))
    {
        enum canPersist = true;
    }
    else
    {
        // TODO Error for non-static local struct?
        enum canPersist = false;
    }
}

template canPersist(T, U : T*)
{
    enum canPersist = false;
}

template canPersist(T, U)// if (!is(T == struct))
{
    enum canPersist = true;
}

template canPersist(T) if (is(T == class))
{
    enum canPersist = false;
}

/**
 * Return the parent types of a persistable struct
 *
 * Any member of T that is a pointer to a struct and is persistable
 * will be returned. Duplicates are removed.
 */
template Parent(T) if (is(T == struct) && canPersist!T)
{
    alias NoDuplicates!(Parent!(typeof(T.tupleof))) Parent;
}

template Parent(T...) if (T.length > 1)
{
    alias TypeTuple!(Parent!(T[0]), Parent!(T[1..$])) Parent;
}

template Parent(T : T*) if (is(T == struct))
{
    alias T Parent;
}

template Parent(T) if (!is(T == struct))
{
    alias TypeTuple!() Parent;
}

version(unittest)
{
    struct A
    {
        int a;
        string b;
    }

    struct B
    {
        A* a;
    }

    struct B2
    {
        B* b;
    }

    struct C
    {
        D* d;
    }

    struct D
    {
        C* c;
    }

    struct E
    {
        F* g;
    }

    struct F
    {
        G* e;
    }

    struct G
    {
        E* e;
    }

    static assert(canPersist!A);
    static assert(canPersist!B);
    static assert(!canPersist!C);
    static assert(!canPersist!D);
    static assert(!canPersist!E);
    static assert(!canPersist!F);
    static assert(!canPersist!G);
    static assert(is(Parent!A == TypeTuple!()));
    static assert(is(Parent!B == TypeTuple!A));
    static assert(is(Parent!B2 == TypeTuple!B));
}

