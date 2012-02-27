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
    private string mTablePrefix;
    private string[] mWherePredicates;
    private Order mOrder;
    private HasBetween[string] mBetween;
    private bool mHasLimit;

    Qt type() @property
    {
        return mQt;
    }

    string tablePrefix() @property
    {
        return mTablePrefix;
    }

    string[] wherePredicates() @property
    {
        return mWherePredicates;
    }

    string[] between() @property
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

    typeof(this) order(Order order)
    in
    {
        assert(mQt == Qt.Select);
    }
    body
    {
        mOrder = order;
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

version(none){
import serenity.persister.Persister;
import serenity.core.Util;

import std.conv;

enum Type
{
    Bool, Byte, Ubyte, Short, Ushort, Int, Uint, Long, Ulong, Float, Double,
    Real, String, Wstring, UbyteArr, Time
}

template TypeMap(T)
{
    static if(is(T == bool))
    {
        alias Type.Bool TypeMap;
    }
    else static if(is(T == byte))
    {
        alias Type.Byte TypeMap;
    }
    else static if(is(T == ubyte))
    {
        alias Type.Ubyte TypeMap;
    }
    else static if(is(T == short))
    {
        alias Type.Short TypeMap;
    }
    else static if(is(T == ushort))
    {
        alias Type.Ushort TypeMap;
    }
    else static if(is(T == int))
    {
        alias Type.Int TypeMap;
    }
    else static if(is(T == uint))
    {
        alias Type.Uint TypeMap;
    }
    else static if(is(T == long))
    {
        alias Type.Long TypeMap;
    }
    else static if(is(T == ulong))
    {
        alias Type.Ulong TypeMap;
    }
    else static if(is(T == float))
    {
        alias Type.Float TypeMap;
    }
    else static if(is(T == double))
    {
        alias Type.Double TypeMap;
    }
    else static if(is(T == string))
    {
        alias Type.String TypeMap;
    }
    else static if(is(T == wstring))
    {
        alias Type.Wstring TypeMap;
    }
    else static if(is(T == ubyte[]))
    {
        alias Type.UbyteArr TypeMap;
    }
    else static if(is(T == DateTime))
    {
        alias Type.Time TypeMap;
    }
    else
    {
        static assert(false, "Unsupported field type");
    }
}

enum QueryType
{
    Select,
    Insert,
    Update,
    Delete,
    InsertSelect,
    CreateTable
}

struct Field
{
    string name;
    Type type;
    Constraint constraints;
    string[Constraint] constraintInfo;
}

class Table
{
    private string mName;
    private Field[] mFields;

    this(string name)
    {
        // TODO Validate table name
        mName = name;
    }

    public string getName()
    {
        return mName;
    }

    public Field[] getFields()
    {
        return mFields;
    }

    public typeof(this) bind(T)(Constraint constraints=None, string[Constraint] constraintInfo=null)
    {
        static assert(is(T == struct), "Type parameter for Table.bind!() must be a struct");
        foreach (i, field; typeof(T.tupleof))
        {
            mFields ~= Field(T.tupleof[i].stringof[T.stringof.length+3..$], TypeMap!(field), constraints, constraintInfo);
        }
        return this;
    }

    public typeof(this) field(string name, Constraint constraints, string[Constraint] constraintInfo=null)
    {
        foreach (ref field; mFields)
        {
            if (field.name == name)
            {
                field = Field(name, field.type, constraints, constraintInfo);
                return this;
            }
        }
        // TODO
        assert(false);
        //mFields ~= Field(name, constraints, constraintInfo);
    }
}

mixin SerenityException!("SqlQuery");

struct Bind
{
    Type type;
    union
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
        real realVal;
        string stringVal;
        wstring wstringVal;
        ubyte[] ubyteArrVal;
        DateTime timeVal;
    }
}

struct Function
{
    enum : uint
    {
        /// Give the current time in UTC
        Now
    }
    alias uint Name;
    Name name;
    Bind[] parameters;
}

struct Value
{
    bool isFunction = false;
    union
    {
        string value;
        Function func;
    }
}

final class Query(T)
{
    private QueryType mQt;
    private Table[] mTables;
    private Table mTable;
    private string[] mColumns;
    private string[] mWhere;
    private Bind[] mBinds;
    private Value[] mValues;
    private long mLimit;
    private long mOffset;

    /**
     * Get the QueryType for this SqlQuery
     *
     * Returns:
     *  QueryType for this SqlQuery
     */
    public QueryType getType()
    {
        return mQt;
    }

    /**
     * Get the name of the table we are currently operating on
     *
     * Returns:
     *  The table name we are currently operating on
     */
    public string tableName()
    {
        return mTable.getName();
    }

    /**
     * Get a list of column names being used in this query
     *
     * Returns:
     *  An array of column names
     */
    public string[] getColumns()
    {
        return mColumns;
    }

    /**
     * Get a list of bound parameters
     *
     * Returns:
     *  The parameters to be bound
     */
    public Bind[] getBoundParameters()
    {
        return mBinds;
    }

    /**
     * Get a list of all the where clauses
     *
     * Returns:
     *  A list of where clauses represented as strings
     */
    public string[] getWhereClauses()
    {
        return mWhere;
    }

    /**
     * Get the maximum number of results to return
     *
     * Returns:
     *  Maximum number of results to return for the query
     */
    public long getLimit()
    {
        return mLimit;
    }

    /**
     * Get the offset to start results from
     *
     * Returns:
     *  Offset to start results from
     */
    public long getOffset()
    {
        return mOffset;
    }

    /**
     * Get a list of values to be INSERTed
     *
     * Returns:
     *  A list of values represented as strings
     */
    public Value[] getValues()
    {
        return mValues;
    }

    /**
     * Get the tables to be created/updated etc
     *
     * Returns:
     *  An array of Tables to be operated on
     */
    public Table[] getTables()
    {
        return mTables;
    }

    /**
     * Used for creating and modifiying tables
     *
     * Params:
     *  name = Name of the table
     * See_Also:
     *  class Table
     * Returns:
     *  A table instance with the given name
     */
    public Table createTable(string name)
    {
        mQt = QueryType.CreateTable;
        mTables ~= new Table(name);
        return mTables[$-1];
    }

    /**
     * Perform a SELECT query
     *
     * Pass an array of column names to get, as in SQL. Pass "*" to get all
     * columns
     *
     * Params:
     *  columns = A list of column names to select
     * Returns:
     *  this for method chaining
     */
    public typeof(this) select(string[] columns...)
    {
        // TODO INSERT ... SELECT
        mQt = QueryType.Select;
        mColumns = columns;
        return this;
    }

    /**
     * Perform an INSERT query
     *
     * Returns:
     *  this for method chaining
     */
    public typeof(this) insert()
    {
        mQt = QueryType.Insert;
        return this;
    }

    /**
     * The INTO clause for an INSERT query
     *
     * Params:
     *  table = Table name to insert into
     *  columns = List of columns for values to go into
     * Returns:
     *  this for method chaining
     */
    public typeof(this) into(string table, string[] columns...)
    {
        if (mQt != QueryType.Insert)
        {
            throw new SqlQueryException("SqlQuery.into() is only valid for INSERT queries");
        }
        mTable = new Table(table);
        mColumns = columns;
        return this;
    }

    /**
     * The VALUES clause for an INSERT query
     *
     * Params:
     *  values = List of values to insert
     * Returns:
     *  this for method chaining
     */
     public typeof(this) values(T...)(T parameters)
     {
         foreach (param; parameters)
         {
             static if (is(typeof(param) == bool))
             {
                 mValues ~= Value(false, param ? "1" : "0");
             }
             else static if (is(typeof(param) == Function))
             {
                 Value v;
                 v.isFunction = true;
                 v.func = param;
                 mValues ~= v;
             }
             else
             {
                 mValues ~= Value(false, to!(string)(param));
             }
         }
         return this;
     }

    /**
     * The FROM clause for a SELECT query
     *
     * Params:
     *  table = Table name to select from
     * Returns:
     *  this for method chaining
     */
    public typeof(this) from(string table)
    {
        if (mQt != QueryType.Select)
        {
            throw new SqlQueryException("SqlQuery.from() is only valid for SELECT queries");
        }
        mTable = new Table(table);
        return this;
    }

    /**
     * The WHERE clause for a SELECT query
     *
     * This may be called multiple times to add multiple WHERE clauses
     * (equivilant to using AND).
     *
     * Params:
     *  clause = A SQL string representing the clause
     * Returns:
     *  this for method chaining
     */
    public typeof(this) where(string clause)
    {
        mWhere ~= clause;
        return this;
    }

    /**
     * Limit the number of values returned
     *
     * Params:
     *  limit = Maximum number of values to return
     * Returns:
     *  this for method chaining
     */
    public typeof(this) limit(long limit)
    {
        mLimit = limit;
        return this;
    }

    /**
     * Offset to start results from
     *
     * Params:
     *  offset = Starting offset for results
     * Returns:
     *  this for method chaining
     */
    public typeof(this) offset(long offset)
    {
        mOffset = offset;
        return this;
    }

    /**
     * Bind ? parameters in a statement
     *
     * Params:
     *  parameters = List of parameters to bind ?'s to
     * Returns:
     *  this for method chaining
     */
     public typeof(this) bind(T...)(T parameters)
     {
         foreach (param; parameters)
         {
             mBinds ~= Bind(TypeMap!(typeof(param)), param);
         }
         return this;
     }

    /**
     * NOW() SQL function
     *
     * Returns:
     *  A Function representing NOW()
     */
    public Function now()
    {
        return Function(Function.Now, null);
    }

    /**
     * Execute a SQL query
     *
     * Params:
     *  bg = Execute the query in a worker thread?
     * Returns:
     *  The result of the query
     */
    public T[] execute()
    {
        if (mQt == QueryType.Select && mColumns.length == 1 && mColumns[0] == "*")
        {
            mColumns = typeof(mColumns).init;
            foreach (i, field; typeof(T.tupleof))
            {
                mColumns ~= T.tupleof[i].stringof[T.stringof.length+3..$] ;
            }
        }
        assert(0, "unimplemented");
        //return Database.execute!T(this);
    }
}
}
