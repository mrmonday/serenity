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

import serenity.core.Controller;

struct Post
{
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
        foreach (post; posts[$..$-10])
        {
            log.info("adding article");
            with (doc.article)
            {
                h2.a.attr("href", "/example/view"/*makeUrl("view", post.id)*/).content = post.title;
                time.content = post.time.toSimpleString();
                p.content = post.content;
            }
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
            posts ~= Post(0, cast(DateTime)Clock.currTime().toUTC(), request.post["title"], request.post["content"]);
            setResponseCode(303);
            // TODO Use some sort of url maker as above.
            setHeader("Location", "/");
        }
        return form;
    }
}
