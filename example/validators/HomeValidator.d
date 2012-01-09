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
        auto title = require("title", "Title is a required field");
        auto content = optional("content");

        // TODO switch to pretty => lambda syntax when dmd 2.058 is released
        title.validate((string str) { return str.length < 255; }, "Titles may be no longer than 255 characters");

        return populate!Article(p);
    }
}
