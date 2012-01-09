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

import std.conv;

class ValidationException : Exception
{
    this()
    {
        super("Validation error");
    }
}

class Validator
{
    struct Contract
    {
        struct DgErrPair
        {
            bool delegate(string) dg;
            string error;
        }
        DgErrPair[] validators;
        void validate(bool delegate(string) dg, string error)
        {
            validators ~= DgErrPair(dg, error);
        }

        private string[] check(string value)
        {
            typeof(return) errors;
            foreach (validator; validators)
            {
                if (!validator.dg(value))
                {
                    errors ~= validator.error;
                }
            }
            return errors;
        }
    }

    private Contract*[string] mRequired;
    private string[string] mRequiredErrors;
    private Contract*[string] mOptional;
    private string[] mErrors;

    string[] errors() @property
    {
        auto errs = mErrors;
        mErrors = [];
        return errs;
    }

    protected Contract* require(string s, string error)
    {
        mRequiredErrors[s] = error;
        return mRequired[s] = new Contract();
    }

    protected Contract* optional(string s)
    {
        return mOptional[s] = new Contract();
    }

    protected T populate(T)(string[string] postData)
    {
        static assert(is(T == struct));
        foreach(key, contract; mRequired)
        {
            auto value = key in postData;
            if (value is null || value.length == 0)
            {
                mErrors ~= mRequiredErrors[key];
            }
            else
            {
                if (auto errors = contract.check(*value))
                {
                    mErrors ~= errors;
                }
            }
        }
        foreach(key, contract; mOptional)
        {
            if (auto value = key in postData)
            {
                auto errors = contract.check(*value);
                if (errors)
                {
                    mErrors ~= errors;
                }
            }
        }
        if (mErrors.length)
        {
            throw new ValidationException;
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

