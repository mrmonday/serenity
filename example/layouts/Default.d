/**
 * Serenity Web Framework Example Plugin
 *
 * layouts/Default.d: Default layout for the Example Plugin
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.layouts.Default;

import serenity.Layout;
import serenity.HtmlDocument;

class Default : Layout
{
    mixin registerLayout!(Default);

    private HtmlDocument mDoc;

    this()
    {
        mDoc = new HtmlDocument;
    }

    public HtmlDocument layout(Controller main, Document content)
    {
        assert(cast(HtmlDocument)content !is null);
        auto doc = new HtmlDocument;
        doc.build(main.getTitle());
        doc.body_() ~= cast(HtmlDocument)content;
        return doc;
    }
}
