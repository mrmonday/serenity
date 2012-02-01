/**
 * Serenity Web Framework
 *
 * core/Controller.d: Provides a base class for controllers
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012 Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Controller;

import serenity.core.Log;
import serenity.core.Util;

public import serenity.document.HtmlDocument;
public import serenity.core.Request;

import std.string;

// TODO Move to util
string ctToLower(string str) pure
{
    char[] mstr = str.dup;
    foreach(i, c; mstr)
    {
        if (c >= 'A' && c <= 'Z')
        {
            mstr[i] += 32;
        }
    }
    return mstr.idup;
}

/**
 * Thrown when Controller not found
 */
mixin SerenityException!("ControllerNotFound", "404");

private alias HtmlDocument function(Request, string[]) _scft;

/**
 * Thrown when the specified Controller is not derived from Controller
 */
mixin SerenityException!("InvalidController");

/**
 * Represents a controller, where logic is implemented in a plugin
 *
 * All controllers should inherit from this
 */
abstract class Controller
{
    private static _scft[string][ClassInfo] mControllers;
    private string[] mArguments;
    private string[string] mHeaders;
    private string mPlugin;
    private string mTitle;
    private Logger mLog;
    private ushort mResponseCode = 200;
    private string mViewMethod = "viewdefault";

    /**
     * Register a class as a controller
     *
     * Examples:
     * ----
     *  class MyController : Controller
     *  {
     *      mixin register!(typeof(this));
     *  }
     * ----
     */
    mixin template register(T : Controller)
    {
        static if (is(typeof(__traits(parent, __traits(parent, __traits(parent, T))).stringof)))
        {
            enum _s_pkg = __traits(parent, __traits(parent, __traits(parent, T))).stringof["package ".length .. $];
            // TODO This will give an ugly message for classes with names of length < "Controller".length
            enum _s_model = T.stringof[0 .. $-`Controller`.length] ~ `Model`;
            static if (mixin(q{is(} ~ _s_pkg ~ q{.models.} ~ _s_model ~ q{.} ~ _s_model ~ q{ : serenity.core.Model.Model)}))
            {
                mixin(q{import } ~ _s_pkg ~ q{.models.} ~ _s_model ~ q{;
                        protected } ~ _s_model ~ q{ model;});
            }

            enum _s_view = T.stringof[0 .. $-`Controller`.length] ~ `View`;
            static if (mixin(q{is(} ~ _s_pkg ~ q{.views.} ~ _s_view ~ q{.} ~ _s_view ~ q{ : serenity.core.View.View)}))
            {
                mixin(q{import } ~ _s_pkg ~ q{.views.} ~ _s_view ~ q{;
                        protected } ~  _s_view ~ q{ view;});
            }

        }
        static this()
        {
            _scft[string] _s_ctGetMembers()
            {
                _scft[string] members;
                foreach(member; __traits(derivedMembers, T))
                {
                    static if (member.length >= "display".length && member[0 .. "display".length] == "display")
                    {
                        mixin(`members["` ~ ctToLower(member) ~ `"] = &` ~ T.stringof ~ `.` ~ member ~ `;`);
                    }
                }
                return members;
            }
            enum _s_members = _s_ctGetMembers();
            Controller.registerController(T.classinfo, _s_members);
        }
        this()
        {
            static if(is(typeof(model) : serenity.core.Model.Model))
            {
                model = new typeof(model);
            }
            static if(is(typeof(view) : serenity.core.View.View))
            {
                view = new typeof(view);
            }
            // Call an initialize method if there is one...
            // This is only needed as we're stealing usage of the default constructor
            static if (is(typeof(initialize())))
            {
                initialize();
            }
        }
    }

    /**
     * Create an instance of the given controller
     *
     * Params:
     *  plugin   = The plugin containing the controller
     *  subClass = The class name of the controller. This should the the same
     *             as the module name. Only one controller may exist per file.
     *  args     = Arguments to pass to the class
     *  code     = The default response code for the controller if an error has
     *             already occurred
     * Throws:
     *  ControllerNotFoundException when the given controller does not exist
     * Returns:
     *  An instance of the requested controller
     */
    public static Controller create(string plugin, string subClass, string action=null, string[] args=null, ushort code=200)
    {
        string cname = plugin ~ ".controllers." ~ subClass ~ "Controller." ~ subClass ~ "Controller";
        auto registered = ClassInfo.find(cname);
        if (registered is null || registered !in mControllers)
        {
            throw new ControllerNotFoundException("Controller not found: " ~ cname);
        }
        auto controller = cast(typeof(this))registered.create();
        controller.mLog = Log.getLogger(cname);
        controller.mArguments = args;
        controller.mHeaders["Content-Type"] = "text/html; charset=utf-8";
        controller.mPlugin = plugin;
        controller.mViewMethod = "display" ~ toLower(action);
        controller.setResponseCode(code);
        return controller;
    }

    /**
     * Check if the given controller exists
     *
     * Params:
     *  plugin   = Name of the plugin containing the controller
     *  subClass = Name of the controller
     *  action   = Name of the action in the given controller
     * Returns:
     *  true if the controller exists
     */
    public static bool exists(string plugin, string subClass, string action="default")
    {
        string cname = plugin ~ ".controllers." ~ subClass ~ "Controller." ~ subClass ~ "Controller";
        auto registered = ClassInfo.find(cname);
        auto ptr = registered in mControllers;
        if (registered is null || ptr is null)
        {
            return false;
        }
        foreach (name, func; *ptr)
        {
            if (name["display".length .. $] == action)
            {
                return true;
            }
        }
        return false;
    }

    /**
     * Get a list of all the view methods in a controller
     *
     * Params:
     *  ci = ClassInfo for the given class
     * Throws:
     *  InvalidControllerException if no methods match
     * Returns:
     *  An array of all valid view methods
     */
    private static _scft[string] getViewMethods(ClassInfo ci)
    {
        return mControllers[ci];
    }

    /**
     * Register the given controller
     *
     * This should not be called directly, this is handled by registerController!(T)
     * Params:
     *  ci = ClassInfo of the controller to register
     * Throws:
     *  InvalidControllerException when the given controller does not extend
     *  Controller
     */
    public static void registerController(ClassInfo ci, _scft[string] methods)
    {
        mControllers[ci] = methods;
    }

    /**
     * Return the logger for the current controller
     *
     * Examples:
     * ----
     *  void myMethod()
     *  {
     *      log.info("myMethod()");
     *  }
     * ----
     * Returns:
     *  Instance of Logger for the current controller
     */
    final protected Logger log()
    {
        return mLog;
    }

    /**
     * Get the HTTP response code of the given controller
     *
     * Returns:
     *  HTTP response code for this controller
     */
    final public ushort getResponseCode()
    {
        return mResponseCode;
    }

    /**
     * Set the HTTP response code for this controller
     *
     * Examples:
     * ----
     *  HtmlDocument view()
     *  {
     *      ...
     *      /// An error occurred
     *      setResponseCode(500);
     *      ...
     *  }
     * ----
     */
    final protected void setResponseCode(ushort code)
    {
        mResponseCode = code;
    }


    /**
     * Get the <title> that's been set for this controller
     *
     * Returns:
     *  The <title> if it has been set, null otherwise
     */
    final public string getTitle()
    {
        return mTitle;
    }

    /**
     * Set the <title> for this controller
     *
     * Params:
     *  title = Content for the title
     */
    final protected void setTitle(string title)
    {
        mTitle = title;
    }

    /**
     * Return a list of headers set by this controller
     *
     * Returns:
     *  The headers set by this controller
     */
    final public string[string] getHeaders()
    {
        return mHeaders.dup;
    }

    /**
     * Set HTTP headers for this controller
     *
     * Examples:
     * ----
     *  HtmlDocument view()
     *  {
     *      ...
     *      /// May as well expire the content at this point
     *      setHeader("Expires", "Fri, 21 Dec 2012 00:00:00 GMT");
     *      ...
     *  }
     * ----
     */
    final protected void setHeader(string name, string value)
    {
        mHeaders[name] = value;
    }

    protected HtmlDocument redirect(string to, ushort status=303)
    {
        setResponseCode(status);
        setHeader("Location", to);
        return new HtmlDocument;
    }

    /**
     * Select the relevant method in a controller to call
     *
     * Methods must be named view* (where * is a wildcard), and the binary
     * must not have the relevant symbols stripped. The methods must also not
     * be final, as this method depends on the method existing in the vtable.
     * You can improve start up time by running the following command:
     * ----
     * $ strip -w \
     * > '-K_D*controllers*view*MFC8serenity7Request7RequestAAaZC8serenity12HtmlDocument12HtmlDocument' \
     * >  bin/serenity.fcgi
     * ----
     * Note that this should not be done for debug builds as stack traces
     * will be completely useless. You should not run a full strip on the binary
     * as this will break actions (and thus most of the MVC).
     *
     * Examples:
     * ----
     *  class MyController : Controller
     *  {
     *      mixin registerController!(MyController);
     *      /// This is called when no other method is specified by the router
     *      HtmlDocument viewDefault(Request request, string[] args)
     *      {
     *          auto doc = new HtmlDocument;
     *          // Do something here
     *          return doc;
     *      }
     *  }
     * ----
     * Returns:
     *  The Document returned by the relevant view* method
     */
    final public Document view(Request request)
    {
        auto registered = *(ClassInfo.find(this.classinfo.name) in mControllers);
        foreach (name, ptr; registered)
        {
            if (name == mViewMethod)
            {
                log.info("Calling method HtmlDocument %s(Request, string[]) @ %#x", mViewMethod, ptr);
                Document delegate(Request, string[]) dg;
                dg.ptr = cast(void*)this;
                dg.funcptr = cast(typeof(dg.funcptr))ptr;
                return dg(request, mArguments);
            }
        }
        throw new ControllerNotFoundException("Action not found: " ~ mViewMethod["display".length .. $]);
    }
}
