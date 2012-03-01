/**
 * Serenity Web Framework
 *
 * persister/Query.d: Provides a generic method for querying a persister
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.persister.Query;

import std.array;
import std.typetuple;

enum QueryType
{
    Invalid,
    CreateTables,
    Insert,
    Select,
    Update
}
private alias QueryType Qt;

template IndexType(T) if (is(typeof(T.tupleof)))
{
    static if (is(typeof({ T t; auto id = t.id;})))
    {
        alias typeof(T.id) IndexType;
    }
    else static if(is(typeof({enum string s = T.indexField;}())))
    {
        mixin(q{alias typeof(T.} ~ T.indexField ~ q{) IndexType;});
    }
    else
    {
        static assert(false, "No index type for " ~ T.stringof);
    }
}

template indexName(T) if (is(IndexType!T))
{
    static if (is(typeof({ T t; auto id = t.id;})))
    {
        enum indexName = "id";
    }
    else static if(is(typeof({enum string s = T.indexField;}())))
    {
        enum indexName = T.indexField;
    }
}

template TablesOf(T)
{
    // TODO Implement this properly
    alias TypeTuple!T TablesOf;
}

private enum HasBetween : bool
{
    No = false,
    Yes = true
}

// TODO Support between(a, ?), between(?, b) and between(a, b)
// TODO There should be a clearer way than between(), eg between(BIND, BIND) but nicer
HasBetween between()
{
    return HasBetween.Yes;
}

final class Query(T)
{
    enum Order : ubyte
    {
        Asc,
        Desc
    }
    private Qt mQt;
    private string[] mColumns;
    private string mTablePrefix;
    private string[] mWherePredicates;
    private Order[string] mOrder;
    private HasBetween[string] mBetween;
    private bool mHasLimit;

    Qt type() @property
    {
        return mQt;
    }

    auto tablePrefix() @property
    {
        return mTablePrefix;
    }

    auto wherePredicates() @property
    {
        return mWherePredicates;
    }

    auto ordering() @property
    {
        return mOrder;
    }

    auto columns() @property
    {
        return mColumns;
    }

    bool hasLimit() @property
    {
        return mHasLimit;
    }

    auto between() @property
    {
        string[] keys;
        foreach (key, value; mBetween)
        {
            keys ~= key;
        }
        return keys;
        // DMD Bug #7602
        //return mBetween.keys;
    }

    typeof(this) createTables(string prefix)
    in
    {
        assert(mQt == Qt.Invalid);
    }
    body
    {
        mQt = Qt.CreateTables;
        mTablePrefix = prefix;
        return this;
    }

    typeof(this) insert(string prefix)
    in
    {
        assert(mQt == Qt.Invalid);
    }
    body
    {
        mQt = Qt.Insert;
        mTablePrefix = prefix;
        return this;
    }

    typeof(this) update(string prefix)
    in
    {
        assert(mQt == Qt.Invalid);
    }
    body
    {
        mQt = Qt.Update;
        mTablePrefix = prefix;
        return this;
    }

    typeof(this) select()
    in
    {
        assert(mQt == Qt.Invalid);
    }
    body
    {
        mQt = Qt.Select;
        return this;
    }

    typeof(this) select(string[] columns...)
    in
    {
        assert(mQt == Qt.Invalid);
    }
    body
    {
        mQt = Qt.Select;
        mColumns = columns;
        return this;
    }

    typeof(this) from(string prefix)
    in
    {
        assert(mQt == Qt.Select);
    }
    body
    {
        mTablePrefix = prefix;
        return this;
    }

    // NOTE column names should be [] delimited unless they use magic indicies
    typeof(this) where(string[] preds...)
    in
    {
        assert(mQt == Qt.Select || mQt == Qt.Update);
        // TODO Validate predicates
    }
    body
    {
        // TODO What about when operating on multiple tables?
        // Don't replace here - allow backends to do it so they can add `` or []
        // or whatever
        //foreach (pred; preds)
        //    pred = pred.replace("$index", indexName!T);
        mWherePredicates ~= preds;
        return this;
    }

    typeof(this) where(string column, HasBetween hasBetween)
    in
    {
        assert(mQt == Qt.Select || mQt == Qt.Update);
    }
    body
    {
        mBetween[column] = hasBetween;
        return this;
    }

    static if (is(IndexType!T))
    {
        typeof(this) order(Order order)
        in
        {
            assert(mQt == Qt.Select);
        }
        body
        {
            mOrder[indexName!T] = order;
            return this;
        }
    }

    typeof(this) orderBy(string column, Order order)
    in
    {
        assert(mQt == Qt.Select);
    }
    body
    {
        mOrder[column] = order;
        return this;
    }

    typeof(this) limit()
    in
    {
        assert(mQt == Qt.Select);
    }
    body
    {
        mHasLimit = true;
        return this;
    }
}
