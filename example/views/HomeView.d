/**
 * Serenity Web Framework Example Plugin
 *
 * views/HomeView.d: Hello world blog example
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.views.HomeView;

import serenity.core.View;

class HomeView : View
{
    mixin register!(typeof(this));
}
