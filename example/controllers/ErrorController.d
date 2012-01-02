/**
 * Serenity Web Framework Example Plugin
 *
 * controllers/ErrorController.d: Handles error requests
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.controllers.ErrorController;

import serenity.core.Controller;

class ErrorController : Controller
{
    mixin register!(typeof(this));

    HtmlDocument displayDefault(Request request, string[] args)
    {
        setTitle("Error");
        log.error(args[0]);
        auto doc = new HtmlDocument;
        doc.pre.content = "Error: " ~ args[0];
        return doc;
    }
}
