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
// TODO These need to be done in core.View
import serenity.document.HtmlDocument;
// TODO This needs to be in serenity.document
import serenity.core.Form;

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
        auto form = new Form;
        form.text("Title", "title");
        form.textArea("Content", "content");
        form.submit(null, null, "Add article");
        doc ~= form;
    }
}
