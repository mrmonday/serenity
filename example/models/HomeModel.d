/**
 * Serenity Web Framework Example Plugin
 *
 * models/HomeModel.d: Hello world blog example
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.models.HomeModel;

import serenity.core.Model;

class HomeModel : Model
{
    mixin register!(typeof(this));
}
