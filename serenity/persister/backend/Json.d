/**
 * Serenity Web Framework
 *
 * persister/backend/Json.d: JSON Persister implementation
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.persister.backend.Json;

import serenity.core.Config;

import serenity.persister.Query;

import serenity.util.Transfer;

import std.file;
import std.json;
import std.path;
import std.stdio;
import std.traits;

/**
 * JSON files are stored in directory/T.stringof.json in the form:
 * [
 *   [ "column_name", "column_name1", ...],
 *   [ "0,0", "0,1", ...],
 *   [ "1,0", "1,1", ...]
 * ]
 */
final class Json
{
    string directory;
    template canPersist(T...)
    {
        // TODO
        enum canPersist = true;
    }

    this(Config config)
    {
        import std.string;
        directory = chomp(config["directory"], r"\/");
    }

    this()
    {
        this(.config.serenity.persister.json.section("default"));
    }

    static executable(T)(T row)
    {
        return tuple(T.tupleof);
    }


    static buildQuery(T)(Query!T query)
    {
        return prepare(query);
    }

    // TODO This is duplicated all over the place and should be factored out
    private template fieldName(T, size_t i)
    {
        enum fieldName = T.tupleof[i].stringof[T.stringof.length + 3 .. $];
    }

    T[] execute(T, Params...)(typeof(prepare(new Query!T)) _query, Params params)
    {
        immutable query = transfer!(Query!T)(_query);
        immutable file = directory ~ dirSeparator ~ T.stringof ~ ".json";
        final switch(query.type)
        {
            case QueryType.Invalid:
                throw new Exception("Invalid query");
            case QueryType.CreateTables:
                // TODO Multiple tables?
                if (!file.exists)
                {
                    string columns;
                    foreach (i, field; T.tupleof)
                        columns ~= fieldName!(T, i) ~ ',';
                    File(file, "w").write("[[" ~ columns[0..$-1] ~ "]]");
                }
                return null;
            case QueryType.Insert:
                // TODO Not inserting all columns
                auto json = parseJSON(cast(string)read(file));
                //assert(T.tupleof.length == params.length);
                assert(json.array[0].array.length == params.length);
                JSONValue row;
                row.type = JSON_TYPE.ARRAY;
                foreach (param; params)
                {
                    JSONValue col;
                    static if (is(typeof(param) == bool))
                    {
                        col.type = param ? JSON_TYPE.TRUE : JSON_TYPE.FALSE;
                    }
                    else static if (isIntegral!(typeof(param)))
                    {
                        col.type = JSON_TYPE.INTEGER;
                        col.integer = param;
                    }
                    else static if (isFloatingPoint!(typeof(param)))
                    {
                        col.type = JSON_TYPE.FLOATING;
                        col.floating = param;
                    }
                    else static if (isSomeString!(typeof(param)))
                    {
                        col.type = JSON_TYPE.STRING;
                        col.str = param;
                    }
                    else static if (is(typeof(param) == DateTime))
                    {
                        col.type = JSON_TYPE.STRING;
                        col.str = param.toISOExtString();
                    }
                    else
                    {
                        static assert(false, "Unhandled field type: " ~ typeof(param).stringof);
                    }
                    row.array ~= col;
                }
                json.array ~= row;
                File(file, "wb").rawWrite(toJSON(&json));
                return null;
            case QueryType.Select:
                JSONValue json = parseJSON(cast(string)read(file));
                break;
            case QueryType.Update:
                break;
        }
    }

}
