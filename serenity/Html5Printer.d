/**
 * Serenity Web Framework
 *
 * Html5Printer.d: Print an HtmlDocument as HTML 5
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011 Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Html5Printer;

package import serenity.HtmlDocument;
import serenity.DocumentPrinter;

import std.algorithm;

string[] noClosingTag;

static this()
{
    // TODO Complete this list
    noClosingTag = [ "input", "meta" ];
}

class Html5Printer //: DocumentPrinter
{
    void print(HtmlDocument doc, void delegate(string[]...) dg)
    {
        switch (doc.getType())
        {
            case ElementType.Root:
                foreach (child; doc.find("> *"))
                {
                    print(child, dg);
                }
                break;
            case ElementType.Doctype:
                dg("<!doctype html>");
                break;
            case ElementType.Comment:
                dg("<!--", doc.getContent(), "-->");
                break;
                // TODO: Elements with no closing tags
            default:
                // TODO Escape if needed
                dg("<", doc.typeName());
                foreach (attr, val; doc.getAttributes())
                {
                    dg(" ", attr, `="`, val, `"`);
                }
                dg(">");
                dg(doc.getContent());
                foreach (child; doc.find("> *"))
                {
                    print(child, dg);
                }
                if (!noClosingTag.canFind(doc.typeName()))
                {
                    dg("</", doc.typeName(), ">");
                }
                break;
        }
    }
}
