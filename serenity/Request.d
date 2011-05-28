/**
 * Serenity Web Framework
 *
 * Request.d: Represents a request
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Request;

import serenity.Form;
import serenity.Util;

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

struct Post
{
    private string[string] mArgs;

    private static Post opCall(InputStream stdin)
    {
        Post post = void;
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
                    post.mArgs[key] = buffer;
                    buffer = null;
                    break;
                case '%':
                    char[] digits;
                    digits.length = 2;
                    // BUG Validate
                    try
                    {
                        stdin.read(digits);
                    }
                    catch
                    {
                        throw new RequestException("Invalid POST arguments");
                    }
                    buffer ~= to!string(parse!int(digits, 16));
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
        post.mArgs[key] = buffer;
        return post;
    }
   
    public string opIndex(string name)
    {
        return mArgs[name];
    }

    public Form form(string action)
    {
        return new Form(Form.Method.Post, action, mArgs);
    }
}

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
    private string[string] mArgs;
    private Method    mMethod   = Method.Get;
    private Post      mPost;
    private Protocol  mProtocol = Protocol.Cli;

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
            mPost = Post(stdin);
        }
        // TODO Parse args properly
        if (mProtocol == Protocol.Cli && cliArgs.length > 1)
        {
            mArgs["REQUEST_URI"] = cliArgs[1];
            // This is wrong :3
            mArgs["PATH_INFO"] = cliArgs[1];
        }
    }

    /**
     * Get the request protocol
     *
     * Returns:
     *  A Request.Protocol representing the protocol used by the current request
     */
    public Protocol protocol()
    {
        return mProtocol;
    }

    /**
     * Get the request method
     *
     * Returns:
     *  A Request.Method representing the method used for the current request
     */
    public Method method()
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
    public Post post()
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
        try
        {
            return mArgs[name];
        }
        catch
        {
            return null;
        }
    }
}
