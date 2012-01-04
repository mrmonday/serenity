/**
 * Serenity Web Framework
 *
 * core/Form.d: A wrapper around Document for simple form creation
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.core.Form;

import serenity.document.HtmlDocument;
import serenity.core.Request;
import serenity.core.Util;

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
        ret ~= `public void ` ~ type ~ `(string label, string name, string value=null)
                {
                    auto par = mForm.p;
                    auto el = par.input.attr("type", toLower("` ~ type ~ `"c));
                    if (label !is null)
                    {
                        par.label(true).attr("for", name).content = label;
                        el.attr("id", name);
                    }
                    el.attr("name", name);
                    `;
                // Passwords should not be auto-filled
                if (type != "password")
                {
                    ret ~=
                    `
                    if (value is null)
                    {
                        if (auto ptr = name in Request.current.postData)
                        {
                            el.attr("value", *ptr);
                        }
                    }
                    else
                    {
                        el.attr("value", value);
                    }
                    `;
                }
                else
                {
                    ret ~= q{el.attr("value", value);};
                }
        ret ~= `}`;
    }
    return ret;
}

class Form : HtmlDocument
{
    protected HtmlDocument mForm;
    this()
    {
        super();
        auto request = Request.current;
        // TODO needs to be a way to specify post/get
        mForm = super.form.attr("method", "post")
                          .attr("action", request.getHeader("REQUEST_URI"));
    }

    public void textArea(string label, string name, string value=null)
    {
        auto par = mForm.p;
        par.label.attr("for", name).content = label;
        if (value is null)
        {
            if (auto ptr = name in Request.current.postData)
            {
                value = *ptr;
            }
        }
        par.textarea.attr("id", name).attr("name", name).content = value;
    }
    mixin(genInputMethods());
}
