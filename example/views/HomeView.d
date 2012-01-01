/**
 * Serenity Web Framework Example Plugin
 *
 * views/HomeView.d: Hello world blog example
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.views.HomeView;

// TODO Can this import be factored out?
// NOTE Only need Article from here, dmd bug #314 causes issues though
import example.models.HomeModel;

import serenity.core.View;
import serenity.document.HtmlDocument;

class HomeView : View
{
    void displayArticle(HtmlDocument doc, Article article)
    {
        auto a = doc.article;
        a.h2.a.attr("href", "/example/view"/*makeUrl("view", post.id)*/).content = article.title;
        a.time.content = article.time.toSimpleString();
        a.p.content = article.content;
    }

    void displayAddArticle(HtmlDocument doc)
    {
        // TODO This needs to be nicer...
        //      One step at a time though.
        auto form = doc.form.attr("method", "post")
                            // TODO Fix action URL
                            .attr("action", "example/Home/addpost");
        auto title = form.p;
        form.label.attr("for", "title").content = "Title";
        form.input.attr("id", "title")
               .attr("name", "title")
               .attr("type", "text");
        auto content = form.p;
        content.label.attr("for", "content").content = "Content";
        content.textarea.attr("id", "content")
                        .attr("name", "content");
        form.p.input.attr("value", "Add post")
                    .attr("type", "submit");
    }
}
