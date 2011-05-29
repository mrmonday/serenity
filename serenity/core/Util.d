/**
 * Serenity Web Framework
 *
 * core/Util.d: Utilities for Serenity
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Util;

/**
 * Quick and dirty hack for making the first character of a string lower case
 *
 * Note: The first character must be upper case
 *
 * Params:
 *  str = string to operate on
 * Returns:
 *  Same string but with the first character using lowercase
 */
string fcToLower(string str)
{
    assert(str[0] >= 'A' && str[0] <= 'Z');
    return cast(char)(str[0]+32) ~ str[1..$];
}

/**
 * Quick and dirty hack for making the first character of a string upper case
 *
 * Note: The first character must be lower case
 *
 * Params:
 *  str = string to operate on
 * Returns:
 *  Same string but with the first character using uppercase
 */
string fcToUpper(string str)
{
    assert(str[0] >= 'a' && str[0] <= 'z');
    return cast(char)(str[0]-32) ~ str[1..$];
}

/// Base exception for all exceptions in Serenity
abstract class SerenityBaseException : Exception
{
    protected ushort mCode = 500;

    /**
     * Constructor for SerenityBaseException
     *
     * Params:
     *  msg = Exception message
     *  code = HTTP status code to use when uncaught
     */
    this(string msg, ushort code=500, string file="", size_t line=0)
    {
        mCode = code;
        super(msg, file, line);
    }

    /**
     * HTTP status code for this exception
     *
     * Returns:
     *  HTTP status code to use when this exception is uncaught
     */
    ushort getCode()
    {
        return mCode;
    }
}

/// Create an exception class with the given name ~ "Exception"
mixin template SerenityException(string name, string code="500", string file=__FILE__, size_t line=__LINE__)
{
    mixin(`class ` ~ name ~ `Exception : SerenityBaseException
           {
               /// code is used to set the HTTP status code when uncaught
               this(string msg, ushort code=` ~ code ~ `)
               {
                   super(msg, code, "` ~ file ~ `", ` ~ line.stringof ~ `);
               }
           }`);
}

