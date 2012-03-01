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

import serenity.core.Config;
import serenity.persister.Query;

import std.array;
import std.range;
import std.typetuple;

public import std.datetime;

version (EnableSqlitePersister)
{
    import serenity.persister.backend.Sqlite;
}

string getBackends()
{
    if (__ctfe)
    {
        string[] backends;
        version (EnableSqlitePersister)
        {
            backends ~= "Sqlite";
        }
        assert(backends.length, "No Persister backend enabled");
        string ret = backends[0];
        foreach (backend; backends[1..$])
        {
            ret ~= ',' ~ backend;
        }
        return ret;
    }
    assert(0);
}

template isPersisterBackend(T...)
{
    static if (T.length == 1)
    {
        enum isPersisterBackend = is(typeof({
            static struct Test
            {
                int a;
            }
            static struct Indexable
            {
                int id;
            }
            alias T[0] Backend;

            // Provides a canPersist template
            static assert(Backend.canPersist!(typeof(Test.tupleof)) && Backend.canPersist!(typeof(Indexable.tupleof)));
            Test t;
            Indexable i;

            // Can be constructed with and without configuration values
            Backend b = new Backend;
            b = new Backend(config);

            // Can build and execute queries, both indexable and non-indexable
            // They should also be able to expand a struct into a tuple of basic types
            Test[] result = b.execute!Test(Backend.buildQuery(new Query!Test), Backend.executable(t).field);
            Indexable[] result1 = b.execute!Indexable(Backend.buildQuery(new Query!Indexable), Backend.executable(i).field);
        }));
    }
    else
    {
        enum isPersisterBackend = isPersisterBackend!(T[0]) && isPersisterBackend!(T[1..$]);
    }
}

/// Tuple of all enabled backends
mixin(q{private alias TypeTuple!(} ~ getBackends() ~ q{) PersisterBackends;});
static assert(isPersisterBackend!(PersisterBackends), "One or more of the enabled persistance backends "
                                                      "does not meet the required functionality of a persister.");

/// The default backend
// TODO This should be configurable with the build script
private alias PersisterBackends[0] DefaultBackend;

class Persister(T, Backend = DefaultBackend) if (staticIndexOf!(Backend, PersisterBackends) != -1 &&
                                                 (is(T == struct) || is(T == class)) &&
                                                 T.tupleof.length > 0 &&
                                                 Backend.canPersist!(typeof(T.tupleof)))
{
    enum prefix = "serenity_";
    private Backend mBackend;

    Backend backend() //const @property
    {
        return mBackend;
    }

    this()
    {
        mBackend = new Backend;
    }

    this(Config config)
    {
        mBackend = new Backend(config);
    }

    void initialize()
    {
        enum query = Backend.buildQuery({
            auto q = new Query!T;
            return q.createTables(prefix);
        }());
        mBackend.execute!T(query);
    }

    T opCatAssign(T row)
    {
        enum query = Backend.buildQuery({
            auto q = new Query!T;
            return q.insert(prefix);
        }());
        mBackend.execute!T(query, Backend.executable(row).field);
        return row;
    }

    static if (is(IndexType!T))
    {
        private alias IndexType!T IDT;

        version (DmdBug7079Fixed)
        Dollar opDollar()
        {
            return Dollar();
        }

        T opIndex(IDT idx)
        {
            enum query = Backend.buildQuery({
                auto q = new Query!T;
                return q.select.from(prefix).where("$index = ?");
            }());
            auto results = mBackend.execute!T(query, idx);
            // TODO Is T.init the behaviour we actually want?
            return results.length ? results[0] : T.init;
        }

        T opIndexAssign(T row, IDT idx)
        {
            enum query = Backend.buildQuery({
                auto q = new Query!T;
                return q.update(prefix).where("$index = ?");
            }());
            mBackend.execute!T(query, Backend.executable(row).field, idx);
            return row;
        }

        T[] opSlice(IDT a, IDT b)
        {
            enum query = Backend.buildQuery({
                auto q = new Query!T;
                return q.select.from(prefix).order(Query!T.Order.Asc).where("$index", between());
            }());
            return mBackend.execute!T(query, a, b);
        }

        T[] opSlice(IDT a, Dollar b)
        {
            enum queryAToEnd = Backend.buildQuery({
                auto q = new Query!T;
                return q.select.from(prefix).order(Query!T.Order.Asc).where("$index > ?");
            }());
            if (b.value == 0)
            {
                return mBackend.execute!T(queryAToEnd, a);
            }
            assert(false, "persister[a..$-b] is not currently implemented");
        }

        T[] opSlice(Dollar a, Dollar b)
        {
            enum queryEndToB = Backend.buildQuery({
                auto q = new Query!T;
                return q.select.from(prefix).order(Query!T.Order.Desc).limit();
            }());
            if (a.value == 0)
            {
                return mBackend.execute!T(queryEndToB, b.value);
            }
            if (b.value == 0)
            {
                // TODO Maybe we should switch to ranges for slicing?
                return array(retro(mBackend.execute!T(queryEndToB, a.value)));
            }
            assert(false, "persister[$-a..$-b] is not currently implemented");
        }
    }
    // TODO Other opSlice method
    // TODO opIndexAssign, opSliceAssign
}

/**
 * Represent an index for slicing and indexing.
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
 * TODO Remove once dmd bug 7097 is fixed
 */
public Dollar __dollar()
{
    return Dollar();
}
