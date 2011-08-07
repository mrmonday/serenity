/**
 * Serenity Web Framework
 *
 * document/Html5Printer.d: Print an HtmlDocument as HTML 5
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011 Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.document.Html5Printer;

package import serenity.document.HtmlDocument;

import std.algorithm;

string[] noClosingTag;

static this()
{
    // TODO Complete this list
    noClosingTag = [ "input", "meta" ];
}

class Html5Printer
{
    void print(HtmlDocument doc, void delegate(string[]) _dg)
    {
        // TODO Remove this ugly hack - it's a work around for dmd bug #6341
        void dg(string[] strs...)
        {
            _dg(strs);
        }
        switch (doc.getType())
        {
            case ElementType.Root:
                foreach (child; doc.find("> *"))
                {
                    print(child, _dg);
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
                    print(child, _dg);
                }
                if (!noClosingTag.canFind(doc.typeName()))
                {
                    dg("</", doc.typeName(), ">");
                }
                break;
        }
    }
}
