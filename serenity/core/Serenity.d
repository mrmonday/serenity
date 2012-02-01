/**
 * Serenity Web Framework
 *
 * core/Serenity.d: Entry point for Serenity applications
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Serenity;

import serenity.backend.Backend;
import serenity.core.Config;
import serenity.core.Controller;
import serenity.core.Dispatcher;
import serenity.document.HtmlPrinter;
import serenity.core.Request;

import serenity.core.Log;
import serenity.core.Router;

import std.datetime;
import std.getopt;
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

    private static bool initArgs(ref string[] args)
    {
        // Must be saved as getopt eats arguments
        string appName = args[0];
        bool exit, configured;
        void printHelp()
        {
            import std.stdio;
            writefln("Serenity Web Framework v%s", "0.1 pre-alpha");
            writefln("usage: %s [options]", appName);
            writeln("");
            writeln("Options:");
            writeln("   --config=<file>                 use <file> to configure serenity");
            writeln("   --help                          print this help message");
            exit = true;
        }
        getopt(args, "c|config", (string arg)
                                 {
                                     serenity.core.Config.config = Config(arg);
                                     configured = true;
                                 },
                     "h|help", &printHelp);
        if (!configured)
        {
            // Ignore failure
            scope(failure) return exit;
            serenity.core.Config.config = Config("config.ini");
        }
        return exit;
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
    public static int exec(ref string[] args)
    {
        mDispatcher = new Dispatcher;
        if (initArgs(args))
        {
            return 1;
        }
        Router.initialize();
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
            log.info("Accepting new request");
            sw.start;
            
            /// Handle the request
            auto request = new Request(stdin, stdout, stderr, env, mArgs);
            auto response = mDispatcher.dispatch(request);
            response.send(stdout);
            
            sw.stop;
            log.info("Request complete in %sµs", sw.peek.to!("usecs", ulong));
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
