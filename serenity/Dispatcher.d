/**
 * Serenity Web Framework
 *
 * Dispatcher.d: Dispatch a request
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Dispatcher;

import serenity.Document;
import serenity.Request;
import serenity.Response;
import serenity.Router;
import serenity.Util;

class Dispatcher
{
    public Response dispatch(Request request)
    {
        try
        {
            auto controller = Router.match(request.getHeader("PATH_INFO"));
            auto doc = controller.view(request);
            auto layout = controller.getLayout();
            doc = layout.layout(controller, doc);
            return new Response(request, controller.getHeaders(), doc, controller.getResponseCode());
        }
        catch (SerenityBaseException e)
        {
            auto controller = Router.getErrorController(e.getCode(), e.msg);
            auto doc = controller.view(request);
            auto layout = controller.getLayout();
            doc = layout.layout(controller, doc);
            return new Response(request, controller.getHeaders(), doc, controller.getResponseCode());
        }
        catch (Exception e)
        {
            //char[] err;
            //e.writeOut((char[] str) { err ~= str; });
            auto controller = Router.getErrorController(500, e.toString());
            auto doc = controller.view(request);
            auto layout = controller.getLayout();
            doc = layout.layout(controller, doc);
            return new Response(request, controller.getHeaders(), doc, controller.getResponseCode());
        }
    }
}
