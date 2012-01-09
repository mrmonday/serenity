/**
 * Serenity Web Framework Example Plugin
 *
 * models/HomeModel.d: Hello world blog example
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.models.HomeModel;

import example.validators.HomeValidator;

import serenity.core.Model;

// TODO Remove this once we've switched to opDollar
public import serenity.core.Model : __dollar;

struct Article
{
    ulong id;
    DateTime time;
    string title;
    string content;
}

class HomeModel : Model
{
    mixin register!(typeof(this));

    private Persister!Article mArticles;

    void initialize()
    {
        mArticles = new Persister!Article;
        // TODO This needs doing properly (ie not on every request!).
        mArticles.initialize();
    }

    @property auto articles()
    {
        return mArticles;
    }

    bool addArticle(string[string] p)
    {
        scope(failure) return false;

        auto article = validator.validate(p);
        article.time = cast(DateTime)Clock.currTime().toUTC();
        mArticles ~= article;

        return true;
    }
}
