/**
 * Serenity Web Framework
 *
 * backend/FastCGI.d: FastCGI backend for Serenity
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.backend.FastCGI;

import serenity.bindings.FastCGI;

import serenity.backend.Backend;
import serenity.core.Serenity;

import std.conv;
import std.stream;
import std.string;
import std.typecons;

final class FastCGIInputStream : WhiteHole!InputStream
{
    private FCGX_Stream* mStream;
    private this(FCGX_Stream* stream)
    {
        mStream = stream;
    }

    override void read(out char ch)
    {
        ch = cast(char)FCGX_GetChar(mStream);
    }

    override bool eof()
    {
        return FCGX_HasSeenEOF(mStream) == -1;
    }
}

final class FastCGIOutputStream : WhiteHole!OutputStream
{
    private FCGX_Stream* mStream;
    private this(FCGX_Stream* stream)
    {
        mStream = stream;
    }

    // TODO: Should throw on error
    override void write(const(char)[] str)
    {
        FCGX_PutStr(str.ptr, str.length, mStream);
    }

    // TODO: Should throw on error
    override void writeLine(const(char)[] str)
    {
        FCGX_PutStr((str ~ "\r\n").ptr, str.length + 2, mStream);
    }
}

final class FastCGI : Backend
{
    private string[string] fcgiEnvToEnv(FCGX_ParamArray envp) const
    {
        string[string] ret;
        for(; *envp !is null; envp++)
        {
            auto split = split(to!string(*envp), "=");
            ret[split[0]] = split[1];
        }
        return ret.dup;
    }

    int loop()
    {
        FCGX_Stream*    stdin;
        FCGX_Stream*    stdout;
        FCGX_Stream*    stderr;
        FCGX_ParamArray envp;
        while (FCGX_Accept(&stdin, &stdout, &stderr, &envp) >= 0)
        {
            Serenity.run(new FastCGIInputStream(stdin),
                         new FastCGIOutputStream(stdout),
                         new FastCGIOutputStream(stderr),
                         fcgiEnvToEnv(envp));
        }
        return 0;
    }
}
