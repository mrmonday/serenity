/**
 * Serenity Web Framework Example Plugin
 *
 * views/HomeValidator.d: Hello world blog example
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module example.validators.HomeValidator;

import serenity.core.Validator;

import example.models.HomeModel;

class HomeValidator : Validator
{
    auto validate(string[string] p)
    {
        auto title = require("title");
        auto content = optional("content");

        title.maxLength = 255;

        return populate!Article(p);
    }
}
