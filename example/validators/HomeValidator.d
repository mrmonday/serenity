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
    mixin register!(typeof(this));
}
