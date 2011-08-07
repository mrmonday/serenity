/**
 * Serenity Web Framework
 *
 * document/HtmlPrinter.d: Used to print HTML 5 with HTML 4 wrappers
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.document.HtmlPrinter;

import serenity.document.Html5Printer;

class HtmlPrinter : Html5Printer
{
    override void print(HtmlDocument doc, void delegate(string[]) dg)
    {
        // TODO * Wrap HTML5 elements in <div>'s
        //      * <meta charset=""> to <meta http-equiv="Content-type"...>
        super.print(doc, dg);
    }
}
