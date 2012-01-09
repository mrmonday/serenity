/**
 * Serenity Web Framework
 *
 * core/Model.d: Provides a base class for models
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, 2012 Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Model;

public import serenity.persister.Persister;

abstract class Model
{
    /**
     * Register a class as a model
     *
     * Examples:
     * ----
     *  class MyModel : Model
     *  {
     *      mixin register!(typeof(this));
     *  }
     * ----
     */
    mixin template register(T : Model)
    {
        static if (is(typeof(__traits(parent, __traits(parent, __traits(parent, T))).stringof)))
        {
            // TODO This should probably be unified with Controller.register
            enum _s_pkg = __traits(parent, __traits(parent, __traits(parent, T))).stringof["package ".length .. $];
            // TODO This will give an ugly message for classes with names of length < "Model".length
            enum _s_validator = T.stringof[0 .. $-`Model`.length] ~ `Validator`;
            static if (mixin(q{is(} ~ _s_pkg ~ q{.validators.} ~ _s_validator ~ q{.} ~ _s_validator ~ q{ : serenity.core.Validator.Validator)}))
            {
                mixin(q{import } ~ _s_pkg ~ q{.validators.} ~ _s_validator ~ q{;
                        protected } ~ _s_validator ~ q{ validator;});
            }
        }
        this()
        {
            // TODO This could probably (and should probably) be done without a static constructor
            static if(is(typeof(validator) : serenity.core.Validator.Validator))
            {
                validator = new typeof(validator);
            }
            // Call an initialize method if there is one...
            // This is only needed as we're stealing usage of the default constructor
            static if (is(typeof(initialize())))
            {
                initialize();
            }
        }

        static if(is(typeof(validator) : serenity.core.Validator.Validator))
        {
            string[] errors() @property
            {
                return validator.errors;
            }
        }
    }

}
