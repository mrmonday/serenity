/**
 * Serenity Web Framework Example Plugin
 *
 * controllers/Home.d: Hello world blog example
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.controllers.Home;

import serenity.Controller;

import example.models.Home : Model = Home;

class Home : Controller
{
    mixin registerController!(Home, Model);
    
    HtmlDocument viewDefault(Request, string[] args)
    {
        setTitle("Home controller");

        auto doc = new HtmlDocument;
        foreach (post; model.getPosts(10))
        {
            auto article = doc.article(true);
            article.h2.a.attr("href", "/example/view"/*makeUrl("view", post.id)*/).content = post.title;
            article.time.content = post.time.toISOExtendedString();
            article.p.content = post.content;
        }
        return doc;
    }

    HtmlDocument viewAddPost(Request request, string[])
    {
        setTitle("Add post");

        auto form = request.post.form(request.getHeader("REQUEST_URI"));
        form.text("Title", "title").validateLength(1, 255);
        form.textArea("Content", "content").validateLength(1, size_t.max);
        form.submit(null, null, "Add post");
        if (form.validate())
        {
            model.createPost(request.post.get("title"), request.post.get("content"));
            setResponseCode(303);
            setHeader("Location", "/serenity/");
        }
        return form;
    }
}
