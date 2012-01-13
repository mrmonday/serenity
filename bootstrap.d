/**
 * Serenity Web Framework
 *
 * bootstrap.d: Bootstrap the framework for this applications
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module bootstrap;

import serenity.core.Serenity;

/// This is required to make sure static constructors and unittests run
import mvc;

int main(string[] args)
{
    /// Launch Serenity
    return Serenity.exec(args);
}
