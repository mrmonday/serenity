/**
 * Serenity Web Framework
 *
 * core/Router.d: Route a request from a given path to the correct controller
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Router;

import std.algorithm;
import std.string;

import serenity.core.Controller;
import serenity.core.Util;

mixin SerenityException!("Router");

private final class Route
{
    private enum Part
    {
        Text,
        Plugin,
        Controller,
        Action,
        Arguments
    }
    private struct Route
    {
        string plugin;
        char[] controller;
        string action;
        string[] args;
    }
    Part[] mPattern;
    string[] mText;
    Route mRoute;
    Route mPath;

    /**
     * Construct a new route
     *
     * Params:
     *  pattern = Pattern this route should match
     *  route = String representing the controller to route to
     */
    this(string pattern, string route)
    {
        assert(pattern[0] == '/');
        parsePattern(pattern);
        parseRoute(route);
    }

    /**
     * Parse a URL pattern into its component parts
     *
     * Params:
     *  pattern = Pattern to parse
     */
    private void parsePattern(string pattern)
    {
        for (size_t i = 0; i < pattern.length;)
        {
            size_t j = i;
            while (j < pattern.length && pattern[j] != '[')
            {
                j++;
            }
            if (i != j)
            {
                mPattern ~= Part.Text;
                mText ~= pattern[i..j];
                i = j;
            }
            while (j < pattern.length && pattern[j] != ']')
            {
                j++;
            }
            if (i != j)
            {
                switch (pattern[i..++j])
                {
                    case "[plugin]":
                        mPattern ~= Part.Plugin;
                        break;
                    case "[controller]":
                        mPattern ~= Part.Controller;
                        break;
                    case "[action]":
                        mPattern ~= Part.Action;
                        break;
                    case "[args]":
                        mPattern ~= Part.Arguments;
                        if (j != pattern.length)
                        {
                            throw new RouterException("Invalid router pattern: [args] can only be used at the end of a URL pattern");
                        }
                        break;
                    default:
                        throw new RouterException("Invalid router pattern: [" ~ pattern[i..j] ~ "]");
                }
                i = j;
                continue;
            }
        }
    }

    private this(){}
    unittest
    {
        with (new .Route)
        {
            parsePattern("/");
            assert(mPattern.length == 1);
            assert(mPattern[0] == Part.Text);
            assert(mText[0].length == 1);
            assert(mText[0] == "/");

            mPattern = typeof(mPattern).init;
            mText = typeof(mText).init;

            parsePattern("/[plugin]");
            assert(mPattern.length == 2);
            assert(mPattern[0] == Part.Text);
            assert(mPattern[1] == Part.Plugin);
            assert(mText[0].length == 1);
            assert(mText[0] == "/");

            mPattern = typeof(mPattern).init;
            mText = typeof(mText).init;

            parsePattern("/[plugin]/[controller]/[action]/[args]");
            assert(mPattern.length == 8);
            assert(mPattern[0] == Part.Text);
            assert(mPattern[1] == Part.Plugin);
            assert(mPattern[2] == Part.Text);
            assert(mPattern[3] == Part.Controller);
            assert(mPattern[4] == Part.Text);
            assert(mPattern[5] == Part.Action);
            assert(mPattern[6] == Part.Text);
            assert(mPattern[7] == Part.Arguments);
            assert(mText.length == 4);
            assert(mText == ["/", "/", "/", "/"]);

            mPattern = typeof(mPattern).init;
            mText = typeof(mText).init;

            parsePattern("/foo/[controller]/[args]");
            assert(mPattern.length == 4);
            assert(mPattern[0] == Part.Text);
            assert(mPattern[1] == Part.Controller);
            assert(mPattern[2] == Part.Text);
            assert(mPattern[3] == Part.Arguments);
            assert(mText.length == 2);
            assert(mText == ["/foo/", "/"]);
        }
    }

    /**
     * Split the given route into its component parts
     *
     * Params:
     *  route = Route in the form plugin/controller/action/[args]
     * TODO:
     *  Some sort of validation? If [foo] is used, is it in the pattern?
     */
    private void parseRoute(string route)
    {
        auto arr = split(route, "/");
        assert(arr.length >= 2 && arr.length <= 4);
        mRoute.plugin = mPath.plugin = arr[0];
        mRoute.controller = mPath.controller = arr[1].dup;
        if (arr.length >= 3)
        {
            mRoute.action = mPath.action = arr[2];
        }
    }

    /**
     * Match a url with this route
     *
     * Params:
     *  url = URL to match
     * Returns:
     *  A uint representing the quality of the match - lower is better but 0 is no match
     */
    public uint match(string url)
    {
        uint quality = 0;
        size_t i = 0;
        size_t text = 0;
        foreach (partNo, part; mPattern)
        {
            switch (part)
            {
                case Part.Text:
                    if (url[i..$].startsWith(mText[text]) &&
                        (i + mText[text].length < url.length && partNo != mPattern.length - 1 ||
                         i + mText[text].length >= url.length && partNo == mPattern.length - 1))
                    {
                        i += mText[text].length;
                        text++;
                        quality++;
                    }
                    else
                    {
                        return 0;
                    }
                    break;
                case Part.Plugin:
                    size_t j = i;
                    // BUG Needs to support all valid identifiers
                    while (j < url.length &&
                           ((url[j] >= 'A' && url[j] <= 'Z') ||
                            (url[j] >= 'a' && url[j] <= 'z')))
                    {
                        j++;
                    }
                    if ((partNo != mPattern.length - 1 && j >= url.length) || (j < url.length && partNo == mPattern.length - 1))
                    {
                        return 0;
                    }
                    if (mRoute.plugin == "[plugin]")
                    {
                        mPath.plugin = tolower(url[i..j]);
                    }
                    i = j;
                    quality += 2;
                    break;
                case Part.Controller:
                    size_t j = i;
                    // BUG Needs to support all valid identifiers
                    while (j < url.length &&
                           ((url[j] >= 'A' && url[j] <= 'Z') ||
                            (url[j] >= 'a' && url[j] <= 'z')))
                    {
                        j++;
                    }
                    if ((partNo != mPattern.length - 1 && j >= url.length) || (j < url.length && partNo == mPattern.length - 1))
                    {
                        return 0;
                    }
                    if (mRoute.controller == "[controller]")
                    {
                        mPath.controller = tolower(url[i..j]).dup;
                        mPath.controller[0] = cast(char)(mPath.controller[0]-32);
                    }
                    i = j;
                    quality += 2;
                    break;
                case Part.Action:
                    size_t j = i;
                    // BUG Needs to support all valid identifiers
                    while (j < url.length &&
                           ((url[j] >= 'A' && url[j] <= 'Z') ||
                            (url[j] >= 'a' && url[j] <= 'z')))
                    {
                        j++;
                    }
                    if ((partNo != mPattern.length - 1 && j >= url.length) || (j < url.length && partNo == mPattern.length - 1))
                    {
                        return 0;
                    }
                    if (mRoute.action == "[action]")
                    {
                        mPath.action = tolower(url[i..j]);
                    }
                    i = j;
                    quality += 2;
                    break;
                case Part.Arguments:
                    mPath.args = split(url[i..$], "/");
                    i++;
                    break;
                default:
                    assert(false);
            }
        }
        return quality;
    }

    unittest
    {
        with (new .Route("/[plugin]/[controller]/[args]", "[plugin]/[controller]/[args]"))
        {
            assert(!match("/"));
            assert(!match("/plugin"));
            assert(!match("/plugin/controller"));
            assert(match("/plugin/controller/my/args") == 7);
            assert(mPath.plugin == "plugin");
            assert(mPath.controller == "Controller");
            assert(mPath.args == ["my", "args"]);
        }
        with (new .Route("/[plugin]/[controller]", "[plugin]/[controller]"))
        {
            assert(!match("/"));
            assert(!match("/plugin"));
            assert(!match("/plugin/controller/my/args"));
            assert(match("/plugin/controller") == 6);
            assert(mPath.plugin == "plugin");
            assert(mPath.controller == "Controller");
            assert(mPath.args == typeof(mPath.args).init);
        }
        with (new .Route("/[plugin]", "[plugin]/Default"))
        {
            assert(!match("/"));
            assert(!match("/plugin/controller"));
            assert(!match("/plugin/controller/my/args"));
            assert(match("/plugin") == 3);
            assert(mPath.plugin == "plugin");
            assert(mPath.controller == "Default");
            assert(mPath.args == typeof(mPath.args).init);
        }
        with (new .Route("/hello-[controller]/foo", "foo/[controller]"))
        {
            assert(!match("/"));
            assert(!match("/plugin"));
            assert(!match("/plugin/controller/my/args"));
            assert(!match("/hello-world/moo"));
            assert(match("/hello-world/foo") == 4);
            assert(mPath.plugin == "foo");
            assert(mPath.controller == "World");
            assert(mPath.args == typeof(mPath.args).init);
        }
        with (new .Route("/hello-[controller]/[action]", "foo/[controller]/[action]"))
        {
            assert(!match("/"));
            assert(!match("/plugin"));
            assert(!match("/plugin/controller/my/args"));
            assert(match("/hello-world/moo") == 6);
            assert(mPath.plugin == "foo");
            assert(mPath.controller == "World");
            assert(mPath.action == "moo", mPath.action);
            assert(mPath.args == typeof(mPath.args).init);
        }
    }
}

static class Router
{
    private static Route[] mRoutes;
    private static string mErrorPlugin;
    private static string mErrorController;

    /**
     * Add an associative array of routes to the router
     *
     * Params:
     *  routes = An associative array of patterns to routes
     */
    public static void addRoutes(string[string] routes)
    {
        foreach (pattern, route; routes)
        {
            addRoute(pattern, route);
        }
    }

    /**
     * Add an individual route to the router
     *
     * Params:
     *  pattern = URL pattern to match
     *  route = Plugin/Controller to route matches to
     */
    public static void addRoute(string pattern, string route)
    {
        mRoutes ~= new Route(pattern, route);
    }

    /**
     * Add routing for error handling
     *
     * Params:
     *  plugin = Plugin to route to
     *  controller = Controller to route to
     */
    public static void errorRoute(string plugin, string controller)
    {
        if (!Controller.exists(plugin, controller))
        {
            throw new RouterException("Invalid error controller: " ~ plugin ~ '.' ~ controller);
        }
        mErrorPlugin = plugin;
        mErrorController = controller;
    }

    /**
     * Get the error controller
     *
     * Params:
     *  code = HTTP Response code
     *  error = Error message
     * Returns:
     *  Error controller as set by errorRoute()
     */
    public static Controller getErrorController(ushort code, string error)
    {
        return Controller.create(mErrorPlugin, mErrorController, "default", [error], code);
    }

    /**
     * Match the given URL with the best matching Route, then return the
     * relevant controller
     *
     * Params:
     *  url = URL to match, sans hostname/protocol
     * Throws:
     *  RouterException on error
     * Returns:
     *  Best matching controller
     */
    public static Controller match(string url)
    {
        Route bestRoute = null;
        uint best = uint.max;

        url = url is null ? "/" : url;
        foreach (route; mRoutes)
        {
            uint match = route.match(url);
            if (match && match < best)
            {
                bestRoute = route;
                best = match;
            }
        }
        if (bestRoute is null)
        {
            throw new RouterException("No route matching url found: " ~ url);
        }
        return Controller.create(bestRoute.mPath.plugin, bestRoute.mPath.controller.idup, bestRoute.mPath.action, bestRoute.mPath.args);
    }
}
