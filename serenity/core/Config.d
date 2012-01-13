/**
 * Serenity Web Framework
 *
 * core/Config.d: Used to configure serenity.
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Config;

import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;

struct Config
{
    private string[string][string] values;
    private string current;

    this(string file)
    {
        string curSection;
        foreach (line; File(file).byLine())
        {
            skipOver(line, "\t ");
            if (startsWith(line, ";"))
            {
                continue;
            }
            if (skipOver(line, "["))
            {
                curSection = to!string(until(line, "]"));
                continue;
            }
            if (auto val = array(splitter(line, "=")))
            {
                values[curSection][strip(val[0].idup)] = strip(val[1].idup);
            }
        }
    }

    string opIndex(string key)
    {
        return values[current][key];
    }

    int opApply(int delegate(const ref string, const ref string) dg)
    {
        auto ptr = current in values;
        if (!ptr)
        {
            return 1;
        }
        foreach(key, val; *ptr)
        {
            if (auto result = dg(key, val))
                return result;
        }
        return 0;
    }

    Config opDispatch(string name)()
    {
        auto c = this;
        c.current = current ? current ~ '.' ~ name : name;
        return c;
    }
}

Config config;

unittest
{
    enum fn = "serenity_config_unittest.ini";
    auto file = File(fn, "w");
    file.write(`; Example configuration file for serenity
[serenity.persister.sqlite]
    file = serenity-test.db

[serenity.log]
    type = stderr
    level = trace

[serenity.router.routes]
    /                                      = example/Home/Default
    /[plugin]                              = [plugin]/Default/Default
    /[plugin]/[controller]                 = [plugin]/[controller]/Default
    /[plugin]/[controller]/[action]        = [plugin]/[controller]/[action]
    /[plugin]/[controller]/[action]/[args] = [plugin]/[controller]/[action]/[args]
`);
    file.close();
    Config c = Config(fn);
    std.file.remove(fn);
}
