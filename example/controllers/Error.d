/**
 * Serenity Web Framework Example Plugin
 *
 * controllers/Error.d: Handles error requests
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.controllers.Error;

import serenity.Controller;

class Error : Controller
{
    mixin registerController!Error;

    HtmlDocument viewDefault(Request request, string[] args)
    {
        setTitle("Error");
        log.error(args[0]);
        auto doc = new HtmlDocument;
        doc.pre.content = "Error: " ~ args[0];
        return doc;
    }
}
