/**
 * Serenity Web Framework
 *
 * Log.d: Logging support for Serenity
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011 Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Log;

import std.stream;
import std.string;

class Logger
{
    private string mName;
    this(string name)
    {
        mName = name;
    }
    bool info(T=void)()
    {
        return true;
    }
    void info(T...)(string msg, T args)
    {
        Log.mStream.writeLine(format("[info] [%s]: " ~ msg, mName, args));
    }
    bool error() { return true; }
    void error(string,...) {}
}

static class Log
{
    /// Logging style
    enum Type
    {
        None   = 0,
        Stdout = 1 << 0,
        Stderr = 1 << 1,
        File   = 1 << 2,
        Files  = 1 << 3,
        Mail   = 1 << 4,
        Socket = 1 << 5
    }
    enum Level
    {
        Trace,
        Info,
        Warn,
        Error,
        Fatal
    }
    private static OutputStream mStream;
    
    private static string mFileFile;
    private static int mFileCount;
    private static long mFileSize;

   // private static InternetAddress mMailServer;
    private static string mMailFrom;
    private static string mMailTo;
    private static string mMailSubject;

    //private static InternetAddress mSocketAddress;

    /**
     * Set the logging type
     *
     * Params:
     *  type = |'d list of logging types
     */
    static void type(Type type)
    {
        /*static LayoutDate layout;
        layout = new LayoutDate;
        TangoLog.root.clear();
        if (type & Type.None)
        {
            return;
        }
        if (type & Type.Stdout)
        {
            assert(0);
        }
        if (type & Type.Stderr)
        {
            TangoLog.root.add(new AppendConsole(layout));
        }
        if (type & Type.File)
        {
            TangoLog.root.add(new AppendFile(mFileFile, layout));
        }
        if (type & Type.Files)
        {
            TangoLog.root.add(new AppendFiles(mFileFile, mFileCount, mFileSize, layout));
        }
        if (type & Type.Mail)
        {
            TangoLog.root.add(new AppendMail(mMailServer, mMailFrom, mMailTo, mMailSubject, layout));
        }
        if (type & Type.Socket)
        {
            TangoLog.root.add(new AppendSocket(mSocketAddress, layout));
        }*/
    }

    /**
     * Get the logger with the given name
     *
     * Params:
     *  name = name of the logger
     * Returns:
     *  The requested logger
     */
    static Logger getLogger(string name)
    {
        return new Logger(name);
    }

    static package void setStream(OutputStream os)
    {
        mStream = os;
    }

    /**
     * Log a generic debugging error message
     *
     * Params:
     *  message = message to print
     *  params  = parameters, if any for formatting
     */
    debug static void error(T...)(string message, T params)
    {
        mStream.writeLine(message);
        //TangoLog.lookup("serenity.debug").error(message, params);
    }

    /**
     * Set the logging level
     *
     * Params:
     *  level = minimum level to log
     * See_Also:
     *  tango.util.log.Log.Logger.Level
     */
    static void level(Level level)
    {
        //TangoLog.root.level(level, true);
    }

    /**
     * Set the options for Type.File and Type.Files logging
     *
     * Params:
     *  file = (Base) file to log to
     *  noFiles = Number of files to log to
     *  maxSize = Maximum log file size before rotation
     */
    static void setFileOptions(string file, int noFiles=0, long maxSize=0)
    {
        mFileFile = file;
        mFileCount = noFiles;
        mFileSize = maxSize;
    }

    /**
     * Set the options for Type.Mail logging
     *
     * Params:
     *  server = Mail server to use
     *  from = Address to send email from
     *  to = Address to send email to
     *  subject = Subject to use for the email
     */
    /*static void setMailOptions(InternetAddress server, string from, string to, string subject)
    {
        mMailServer = server;
        mMailFrom = from;
        mMailTo = to;
        mMailSubject = subject;
    }*/

    /**
     * Set the options for Type.Socket logging
     *
     * Params:
     *  address = Socket to send data to
     */
    /*static void setSocketOptions(InternetAddress address)
    {
        mSocketAddress = address;
    }*/
}
