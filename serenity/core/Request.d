/**
 * Serenity Web Framework
 *
 * core/Request.d: Represents a request
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Request;

//import serenity.core.Form;
import serenity.core.Util;

import std.conv;
import std.stream;

private Request.Method[string] requestMethods;

static this()
{
    with (Request.Method)
    {
        requestMethods = [
                            "OPTIONS"   : Options,
                            "GET"       : Get,
                            "HEAD"      : Head,
                            "POST"      : Post,
                            "PUT"       : Put,
                            "DELETE"    : Delete,
                            "TRACE"     : Trace,
                            "CONNECT"   : Connect
                         ];
    }
}

mixin SerenityException!("Request");

class Request
{
    public enum Protocol
    {
        Http  = 1,   // http
        Https = 2,   // https
        Cli   = 4    // command line
    }
    public enum Method
    {
        Options, Get, Head, Post,
        Put, Delete, Trace, Connect
    }
    private static Request mInstance;
    private string[string] mArgs;
    private Method         mMethod   = Method.Get;
    private string[string] mPost;
    private Protocol       mProtocol = Protocol.Cli;

    private void parsePostData(InputStream stdin)
    {
        string  key;
        string  buffer;
        char    tmp;
        while (!stdin.eof)
        {
            stdin.read(tmp); 
            switch (tmp)
            {
                case '+':
                    buffer ~= ' ';
                    break;
                case '&':
                    mPost[key] = buffer;
                    buffer = null;
                    break;
                case '%':
                    char[] digits;
                    digits.length = 2;
                    // BUG Validate
                    stdin.read(digits[0]);
                    stdin.read(digits[1]);
                    buffer ~= cast(immutable(char))parse!int(digits, 16);
                    break;
                case '=':
                    key = buffer;
                    buffer = null;
                    break;
                // EOF
                case cast(char)-1:
                    break;
                default:
                    buffer ~= tmp;
                    break;
            }
        }
        mPost[key] = buffer;
    }

    /**
     * Construct a new request
     *
     * Params:
     *  fcgiReq = FastCGIRequest for this Request
     *  cliArgs = Array of command line arguments
     */
    this(InputStream stdin, OutputStream stdout, OutputStream stderr, string[string] env, string[] cliArgs)
    {
        mArgs = env;
        if ("REQUEST_URI" in mArgs)
        {
            auto https = "HTTPS" in mArgs;
            mProtocol = https !is null && *https == "on" ? Protocol.Https : Protocol.Http;
        }
        if (auto method = "REQUEST_METHOD" in mArgs)
        {
            mMethod = requestMethods[*method];
        }
        if (mMethod == Method.Post || mMethod == Method.Put)
        {
            parsePostData(stdin);
        }
        // TODO Parse args properly
        if (mProtocol == Protocol.Cli && cliArgs.length > 1)
        {
            mArgs["REQUEST_URI"] = cliArgs[1];
            // This is wrong :3
            mArgs["PATH_INFO"] = cliArgs[1];
        }
        // TODO This will break once we start handling multiple simultaneous requests using fibers
        mInstance = this;
    }

    public static Request current() @property
    {
        return mInstance;
    }

    /**
     * Get the request protocol
     *
     * Returns:
     *  A Request.Protocol representing the protocol used by the current request
     */
    public Protocol protocol() @property
    {
        return mProtocol;
    }

    /**
     * Get the request method
     *
     * Returns:
     *  A Request.Method representing the method used for the current request
     */
    public Method method() @property
    {
        return mMethod;
    }

    /**
     * Get all server arguments
     *
     * Returns:
     *  The arguments passed by the server
     */
    public string[string] getHeaders()
    {
        return mArgs.dup;
    }

    /**
     * Get access to the POST data for this request
     *
     * Returns:
     *  A Post struct with the data for this request
     */
    public string[string] postData() @property
    {
        return mPost;
    }

    /**
     * Get a server argument
     *
     * Params:
     *  name = Name of the argument to get
     * Returns:
     *  The value of the argument, or null if not found
     */
    public string getHeader(string name)
    {
        if (auto header = name in mArgs)
        {
            return *header;
        }
        return null;
    }
}
