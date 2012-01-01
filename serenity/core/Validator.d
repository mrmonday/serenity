/**
 * Serenity Web Framework
 *
 * core/Validator.d: Provides a base class for input validation
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, 2012 Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Validator;

import std.exception;

class Validator
{
    struct Contract
    {
        size_t minLength;
        size_t maxLength = size_t.max;
        void check(string value)
        {
            enforce(value.length > minLength);
            enforce(value.length < maxLength);
        }
    }
    Contract[string] mRequired;
    Contract[string] mOptional;

    protected Contract require(string s)
    {
        return mRequired[s] = Contract();
    }

    protected Contract optional(string s)
    {
        return mOptional[s] = Contract();
    }

    protected T populate(T)(string[string] postData)
    {
        static assert(is(T == struct));
        import std.conv;
        foreach(key, contract; mRequired)
        {
            auto value = key in postData;
            enforce(value, key);
            contract.check(*value);
        }
        foreach(key, contract; mOptional)
        {
            if (auto value = key in postData)
                contract.check(*value);
        }
        T t;
        foreach(i, member; t.tupleof)
        {
            enum memberName = T.tupleof[i].stringof[T.stringof.length + 3 .. $];
            if (auto value = memberName in postData)
            {
                static if(is(typeof(to!(typeof(member))(*value))))
                    t.tupleof[i] = to!(typeof(member))(*value);
            }
        }
        return t;
    }
}

