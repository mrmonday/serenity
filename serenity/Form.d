/**
 * Serenity Web Framework
 *
 * Form.d: A wrapper around Document for simple form creation
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Form;

import serenity.HtmlDocument;
import serenity.Util;

import std.string;

/**
 * Generate methods for <input> tags
 *
 * Returns:
 *  String with all the methods in
 */
string genInputMethods()
{
    static const string[] types =
    [ 
        "button", "checkbox", "color", "date", "datetime", "datetimeLocal",
        "email", "file", "hidden", "image", "month", "number", "password",
        "radio", "range", "reset", "search", "submit", "tel", "text", "time",
        "url", "week"
    ];
    string ret;
    foreach (type; types)
    {
        ret ~= `public Field ` ~ type ~ `(string label, string name, string value=null)
                {
                    auto par = mForm.p;
                    auto el = par.input.attr("type", tolower("` ~ type ~ `"c));
                    if (label !is null)
                    {
                        par.label(true).attr("for", name).content = label;
                        el.attr("id", name);
                    }
                    el.attr("name", name);
                    if (value is null)
                    {
                        if (auto ptr = name in mArgs)
                        {
                            el.attr("value", *ptr);
                        }
                    }
                    else
                    {
                        el.attr("value", value);
                    }
                    mFields ~= new Field(label, name);
                    return mFields[$-1];
                }
                `;
    }
    return ret;
}

class Form : HtmlDocument
{
    enum Method : bool
    {
        Get = false,
        Post = true
    }
    class Field
    {
        private string                    mLabel;
        private string                    mName;
        private string delegate(string)[] mValidators;

        this(string label, string name)
        {
            mLabel = label;
            mName = name;
        }

        /**
         * Get the label for this field, if any
         *
         * Returns:
         *  String containing the label for this field
         */
        public string getLabel()
        {
            return mLabel;
        }

        /**
         * Validate this field using the given validators
         *
         * Params:
         *  value = Value to validate
         * Return:
         *  An array of errors that occured whilst validating
         */
        Error[] validate(string value)
        {
            Error[] errors;
            foreach (validator; mValidators)
            {
                auto err = validator(value);
                if (err != null)
                {
                    errors ~= Error(this, err);
                }
            }
            return errors;
        }

        /**
         * Validate the length of a field
         *
         * Params:
         *  min = Minimum length of the field
         *  max = Maximum length of the field
         * Returns:
         *  this for method chaining
         */
        public Field validateLength(size_t min, size_t max)
        {
            mValidators ~= (string str)
            {
                if (str.length >= min && str.length <= max)
                {
                    return cast(string)null;
                }
                return format("must be between %s and %s characters in length", min, max);
            };
            return this;
        }
    }
    /// Represents an error
    struct Error
    {
        Field  field;
        string message;
    }
    private string[string]   mArgs;
    private Error[]          mErrors;
    private Field[]          mFields;
    private HtmlDocument     mForm;
    private Method           mMethod;

    this(Method method, string action, string[string] args)
    {
        super();
        mForm = form.attr("method", method ? "post" : "get")
                    .attr("action", action);
        mArgs = args;
        mMethod = method;
    }

    /**
     * Validate the fields in this form
     *
     * Params:
     *  prependErrors = Should error messages be prepended to the form
     * Returns:
     *  true for successful validation, false otherwise
     */
    bool validate(bool prependErrors=true)
    {
        if (mMethod != Method.Post || mArgs.length == 0)
        {
            return false;
        }
        foreach (field; mFields)
        {
            auto arg = field.mName in mArgs;
            mErrors ~= field.validate(arg is null ? "" : *arg);
        }
        if (prependErrors)
        {
            foreach_reverse (error; mErrors)
            {
                root.p(true).attr("class", "error").content = error.field.getLabel() ~ " " ~ error.message;
            }
        }
        return mErrors.length ? false : true;
    }

    /**
     * Get the errors for this form
     *
     * Should only be called after validate()
     *
     * Returns:
     *  An array of errors
     */
    Error[] getErrors()
    {
        return mErrors;
    }
    
    public Field textArea(string label, string name, string value=null)
    {
        auto par = mForm.p;
        par.label.attr("for", name).content = label;
        if (value is null)
        {
            if (auto ptr = name in mArgs)
            {
                value = *ptr;
            }
        }
        par.textarea.attr("id", name).attr("name", name).content = value;
        mFields ~= new Field(label, name);
        return mFields[$-1];
    }
    mixin(genInputMethods());
}
