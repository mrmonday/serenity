/**
 * Serenity Web Framework Example Plugin
 *
 * models/Home.d: Example model for blog posts
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.models.Home;

import serenity.Model;

struct Post
{
    int id;
    DateTime time;
    string title;
    string content;
}

class Home : Model
{
    void create()
    {
        with (new SqlQuery)
        {
            createTable("blog")
                       .bind!(Post)(NotNull)
                       .field("id", PrimaryKey | AutoIncrement);
            execute!(Post)();
        }
    }

    Result!(Post) getPosts(long lim, long offs=0)
    {
        with (new SqlQuery)
        {
            select("*").from("blog")
                       .limit(lim)
                       .offset(offs);
            return execute!(Post)();
        }
    }

    void createPost(string title, string content)
    {
        with (new SqlQuery)
        {
            insert.into("blog", "time", "title", "content")
                  .values(now(), title, content);
            execute!(Post)();
        }
    }
}
