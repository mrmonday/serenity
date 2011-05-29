/**
 * Serenity Web Framework
 *
 * core/Serenity.d: Entry point for Serenity applications
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Serenity;

import serenity.backend.Backend;
import serenity.core.Controller;
import serenity.core.Dispatcher;
import serenity.document.HtmlPrinter;
import serenity.core.Request;

public import serenity.core.Log;
public import serenity.core.Router;

import std.datetime;
import std.stream;

version (EnableFastCGIBackend)
{
    import serenity.backend.FastCGI;
    alias FastCGI DefaultBackend;
}
else
{
    static assert(false, "No backends enabled");
}

final class Serenity
{
    private static string[] mArgs;
    private static Dispatcher mDispatcher;
    private static Logger log;
    private static Backend mBackend;

    /**
     * Set the backend to use
     *
     * Only call before Serenity.exec()
     */
    public static void setBackend(Backend backend)
    {
        mBackend = backend;
    }

    /**
     * Execute Serenity
     *
     * This method is used to execute Serenity
     * Examples:
     * ----
     *  int main(string[] args)
     *  {
     *      /// Serenity should be configured here
     *
     *      /// Execute Serenity
     *      return Serenity.exec(args);
     *  }
     * ----
     * See_Also:
     *  bootstrap.d
     * Params:
     *  args = Command line arguments
     * Returns:
     *  Zero (0) on successful termination, non-zero on error 
     */
    public static int exec(string[] args)
    {
        mDispatcher = new Dispatcher;
        mArgs = args;
        log = Log.getLogger("serenity.Serenity");
        if (mBackend is null)
        {
            mBackend = new DefaultBackend;
        }
        return mBackend.loop();
    }

    /**
     * Handle a request
     *
     * This is the main entry point for any request handled by Serenity. This
     * can be called multiple times simoultaneously depending on how many
     * FastCGI threads have been allocated using Serenity.setNumberOfThreads().
     *
     * Returns:
     *  Zero (0) on success, one (1) otherwise
     */
    public static int run(InputStream stdin, OutputStream stdout, OutputStream stderr, string[string] env)
    {
        StopWatch sw;
        try
        {
            Log.setStream(stderr);
            if (log.info) log.info("Accepting new request");
            sw.start;
            
            /// Handle the request
            auto request = new Request(stdin, stdout, stderr, env, mArgs);
            auto response = mDispatcher.dispatch(request);
            response.send(stdout);
            
            sw.stop;
            if (log.info) log.info("Request complete in %sµs", sw.peek.to!("usecs", ulong));
            return 0;
        }
        catch (Exception e)
        {
            sw.stop;
            // TODO Replace this with stderr, shouldn't appear when not debugging
            stdout.write("Status: 500 Internal Server Error\r\n\r\n"c);
            stdout.write("<pre>\n"c);
            stdout.write(e.toString());
            stdout.write("\n</pre>\n"c);
            return 1;
        }
    }
}
