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

struct Post
{
    enum constrain_id = PrimaryKey | AutoIncrement;
    ulong id;
    DateTime time;
    string title;
    string content;
}

class Home : Controller
{
    mixin registerController!(Home);
    Persister!Post posts;

    this()
    {
        posts = new Persister!Post;
        posts.initialize();
    }

    HtmlDocument viewDefault(Request, string[] args)
    {
        setTitle("Home controller");

        auto doc = new HtmlDocument;
        foreach (post; posts[$..-10])
        {
            log.info("adding article");
            auto article = doc.article(true);
            article.h2.a.attr("href", "/example/view"/*makeUrl("view", post.id)*/).content = post.title;
            article.time.content = post.time.toSimpleString();
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
            posts ~= Post(0, cast(DateTime)Clock.currTime().toUTC(), request.post.get("title"), request.post.get("content"));
            setResponseCode(303);
            setHeader("Location", "/~robert/serenity/");
        }
        return form;
    }
}
