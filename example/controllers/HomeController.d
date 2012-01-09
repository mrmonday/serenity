/**
 * Serenity Web Framework Example Plugin
 *
 * controllers/HomeController.d: Hello world blog example
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.controllers.HomeController;

import serenity.core.Controller;

class HomeController : Controller
{
    mixin register!(typeof(this));

    // TODO Switch back to auto when dmd bug #7159 is fixed
    HtmlDocument displayDefault(Request, string[] args)
    {
        setTitle("Home controller");

        auto doc = new HtmlDocument;
        foreach (Article article; model.articles[$..$-10])
        {
            view.displayArticle(doc, article);
        }
        return doc;
    }

    HtmlDocument displayAddPost(Request request, string[])
    {
        setTitle("Add post");
        auto doc = new HtmlDocument;

        if (auto postData = request.postData)
        {
            if (model.addArticle(postData))
            {
                // TODO success message
                return redirect("/");
            }
        }
        if (auto errors = model.errors)
        {
            foreach (error; errors)
            {
                view.displayError(doc, error);
            }
        }
        view.displayAddArticle(doc);
        return doc;
    }
}
