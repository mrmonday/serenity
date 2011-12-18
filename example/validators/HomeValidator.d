/**
 * Serenity Web Framework Example Plugin
 *
 * views/HomeValidator.d: Hello world blog example
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.validators.HomeValidator;

import serenity.core.Validator;

class HomeValidator : Validator
{
    auto validate(Post p)
    {
        auto title = require(p, "title");
        auto content = optional(p, "content");

        title.maxLength = 255;

        return populate!Article();
    }
}
