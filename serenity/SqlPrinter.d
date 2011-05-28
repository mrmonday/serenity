/**
 * Serenity Web Framework
 *
 * SqlPrinter.d: Base class for all SQL printers
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.SqlPrinter;
version(none):
package import serenity.Persister;
package import serenity.persister.Query;
import serenity.Util;

mixin SerenityException!("SqlPrinter");

class SqlPrinter
{
    abstract void print(Query doc, void delegate(string[]...) dg);

    string getQueryString(Query doc)
    {
        string ret;
        print(doc, (string[] text...) { foreach (str; text) { ret ~= str; } });
        return ret;
    }
}
