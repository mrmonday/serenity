/**
 * Serenity Web Framework
 *
 * document/HtmlDocument.d: Represents an HTML document
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, 2012, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.document.HtmlDocument;

public import serenity.document.Document;

import serenity.util.Misc;

import std.array : split;
import std.algorithm;

/// List of non-unique elements
private enum string[] nonUniqueElementList =
[
    "Comment", "A", "Abbr", "Address", "Area", "Article", "Aside", "Audio", "B",
    "Bdo", "Blockquote", "Br", "Button", "Canvas", "Caption", "Cite", "Code", "Col",
    "Colgroup", "Command", "Datalist", "Dd", "Del", "Details", "Dfn", "Div", "Dl", "Dt", "Em", "Embed",
    "Fieldset", "Figcaption", "Figure", "Footer", "Form", "H1", "H2", "H3", "H4", "H5", "H6",
    "Header", "Hgroup", "Hr", "Italic", "Iframe", "Img", "Input", "Ins", "Keygen", "Kbd",
    "Label", "Legend", "Li", "Link", "Map", "Mark", "Menu", "Meta", "Meter", "Nav", "Noscript",
    "Object", "Ol", "Optgroup", "Option", "Output", "P", "Param", "Pre", "Progress",
    "Quote", "Rp", "Rt", "Ruby", "Samp", "Script", "Section", "Select", "Small", "Source", "Span",
    "Strong", "Style", "Sub", "Summary", "Sup", "Table", "Tbody", "Td", "Textarea", "Tfoot", "Th",
    "Thead", "Time", "Tr", "Ul", "Var", "Video", "Wbr"
];

/// List of unique elements
private enum string[] uniqueElementList =
[
    "Doctype", "Base", "Body_", "Head", "Html", "Title"
];

private enum string[] elementList = nonUniqueElementList ~ uniqueElementList;

private string genElEnum()
{
    string e = "private enum ElementType { Root,";
    foreach (i, el; elementList)
    {
        e ~= el;
        if (i != elementList.length - 1)
        {
            e ~= ',';
        }
    }
    e ~= '}';
    return e;
}
mixin(genElEnum());

private string genElementTypeToString()
{
    string ts = `private string elementTypeToString(ElementType et)
                 {
                     final switch(et)
                     {
                         case ElementType.Root:
                            return "Root";
                         // Special cased due to keyword
                         case ElementType.Body_:
                            return "body";
                     `;
    foreach (el; elementList)
    {
        if(el != "Body_")
        {
            ts ~= `case ElementType.` ~ el ~ `:
                      return "` ~ fcToLower(el) ~ `";
                  `;
        }
    }
    ts ~= `          } // End switch
                 } // End function`;
    return ts;
}
mixin(genElementTypeToString());

private string genElMethods()
{
    string methods;
    foreach (el; nonUniqueElementList)
    {
        methods ~= `final public typeof(this) ` ~ fcToLower(el) ~ `(bool prepend = false)
                    {
                        if (prepend)
                        {
                            mChildren = new typeof(this)(this, ElementType.` ~ el ~ `) ~ mChildren[];
                            return mChildren[0];
                        }
                        else
                        {
                            mChildren ~= new typeof(this)(this, ElementType.` ~ el ~ `);
                            return mChildren[$-1];
                        }
                    }`;
    }
    foreach (el; uniqueElementList)
    {
        string elName = fcToLower(el == "Body_" ? "Body" : el);
        methods ~= `final public typeof(this) ` ~ fcToLower(el) ~`()
                    {
                        auto el = root.find("` ~ elName ~ `");
                        if (el && el.length)
                        {
                            return el[0];
                        }
                        else
                        {
                            mChildren ~= new typeof(this)(this, ElementType.` ~ el ~ `);
                            return mChildren[$-1];
                        }
                    }`;
    }
    return methods;
}

mixin SerenityException!("HtmlDocument");
mixin SerenityException!("HtmlDocumentSelector");

class HtmlDocument : Document
{
    private struct SelectorPart
    {
        enum PartType
        {
            Unknown,
            Operator,
            Identifier,
            String,
            Number,
            PseudoClass,
            PseudoElement,
            Whitespace
        }
        PartType type;
        string value = null;

        bool opEquals(ref const SelectorPart other) const
        {
            return other.type == type && other.value == value;
        }
    }
    private alias SelectorPart.PartType SelectorType;

    private string[string] mAttributes;
    private typeof(this) mParent;
    private typeof(this)[] mChildren;
    private ElementType mType;
    private string mContent;

    /**
     * Construct a new HtmlDocument
     *
     * The resulting object will be the root element for the Document
     */
    this()
    {
        mParent = null;
        mType = ElementType.Root;
    }

    /**
     * Set up the default elements for an HtmlDocument
     *
     * Params:
     *  title = contents for the <title> element
     * Throws:
     *  HtmlDocumentException when this is a non-root element
     * Returns:
     *  this for method chaining
     */
    public typeof(this) build(string title = null)
    {
        if (mType != ElementType.Root)
        {
            throw new HtmlDocumentException("Cannot build a non-root HtmlDocument: " ~ elementTypeToString(mType));
        }
        doctype();
        auto html = html();
        html.head.title.content = title;
        html.head.meta.attr("charset", "UTF-8");
        html.body_();
        return this;
    }

    /**
     * Append an HtmlDocument to this HtmlDocument
     *
     * Params:
     *  doc = The HtmlDocument to append
     * Throws:
     *  HtmlDocumentException when doc is a non-root element
     */
    public void opCatAssign(HtmlDocument doc)
    {
        if (doc.mType != ElementType.Root)
        {
            throw new HtmlDocumentException("Cannot append a non-root HtmlDocument: " ~ elementTypeToString(mType));
        }
        mChildren ~= doc.mChildren;
    }

    /**
     * Private constructor for creation of non-root elements
     *
     * Use the individual methods for adding elements to this Document
     */
    private this(typeof(this) p, ElementType et)
    {
        mParent = p;
        mType = et;
    }

    /**
     * HashMap of all the attributes for this element
     *
     * Returns:
     *  HashMap of key, value pairs of attributes for the Document
     */
    public string[string] getAttributes()
    {
        return mAttributes.dup;
    }

    /**
     * Set an attribute for the element
     *
     * Params:
     *  key = Key for the attribute eg "id"
     *  value = Value for the attribute eg "monkey"
     * Returns:
     *  this to allow for chaining
     */
    public typeof(this) attr(string key, string value)
    {
        mAttributes[key] = value;
        return this;
    }

    /**
     * Get an attribute for the element
     *
     * Params:
     *  key = Key of the attribute
     * Returns:
     *  The value of the attribute with the given key
     */
    public string getAttribute(string key)
    {
        try
        {
            return mAttributes[key];
        }
        catch
        {
            return null;
        }
    }

    /**
     * Get the ElementType of this element
     *
     * Returns:
     *  The ElementType for this element
     */
    public ElementType getType()
    {
        return mType;
    }

    /**
     * Set the content for this element
     *
     * Params:
     *  str = Content this element should have
     * Returns:
     *  this to allow for chaining
     */
    public typeof(this) content(string str)
    {
        mContent = str;
        return this;
    }

    /**
     * Get the contents of this element
     *
     * Returns:
     *  The contents set for this element
     */
    public string getContent()
    {
        return mContent;
    }

    /**
     * Get the human readable name for the element's type
     *
     * Returns:
     *  string representing the type of this element
     */
    public string typeName()
    {
        return elementTypeToString(mType);
    }

    /**
     * Return the root element for this document
     *
     * Returns:
     *  Root element for the document
     */
    public typeof(this) root()
    {
        typeof(this) root = this;
        while (root.mParent !is null)
        {
            root = root.mParent;
        }
        return root;
    }

    /**
     * Remove semantically irrelevant whitespace
     *
     * Params:
     *  sel = Array of selector parts
     * Returns:
     *  The array without the unneeded whitespace
     */
    private SelectorPart[] cleanWhitespace(SelectorPart[] sel)
    {
        for (size_t i = 0; i < sel.length; i++)
        {
            if (i + 2 < sel.length &&
                sel[i].type == SelectorType.Identifier &&
                sel[i + 1].type == SelectorType.Whitespace &&
                sel[i + 2].type == SelectorType.Identifier)
            {
                i += 2;
                continue;
            }
            if (sel[i].type == SelectorType.Whitespace)
            {
                sel = sel.remove(i);
                i--;
            }
        }
        return sel;
    }

    /**
     * Lex a CSS selector
     *
     * Params:
     *  sel = Selector to parse
     * Returns:
     *  Array of selector parts
     */
    private SelectorPart[] lexSelector(string sel)
    {
        SelectorPart[] parts;
        bool append(SelectorType t, ref size_t i, size_t j)
        {
           if (i != j)
           {
               parts ~= SelectorPart(t, sel[i..j]);
               i = j;
               return true;
           }
           return false;
        }
        for (size_t i = 0; i < sel.length;)
        {
           size_t j = i;
           // Lex strings
           if (j < sel.length && sel[j] == '"')
           {
               do
               {
                   j++;
               } while (j < sel.length && sel[j] != '"');
               i++;
               if (append(SelectorType.String, i, j))
               {
                   i = ++j;
                   continue;
               }
           }
           // Lex element names
           if (j < sel.length && (sel[j] >= 'A' && sel[j] <= 'Z' || sel[j] >= 'a' && sel[j] <= 'z'))
           {
               while (j < sel.length &&
                        (sel[j] >= 'A' && sel[j] <= 'Z' ||
                         sel[j] >= 'a' && sel[j] <= 'z' ||
                         sel[j] >= '0' && sel[j] <= '9')
                     )
               {
                   j++;
               }
           }
           append(SelectorType.Identifier, i, j);
           // Lex whitespace
           while (j < sel.length && (sel[j] == ' ' || sel[j] == '\t' || sel[j] == '\r' || sel[j] == '\n'))
           {
               j++;
           }
           if (i != j)
           {
               // Standardise whitespace
               parts ~= SelectorPart(SelectorType.Whitespace, " ");
               i = j;
               continue;
           }
           // Generic catch all punctuation
           string toks = ['#', '.', ',', '>', '+', '~', '(', ')', '[', ']', '=', '^', '$', '*', '|'];
           if (i < sel.length && toks.canFind(sel[i]))
           {
               // Special case X=
               if (j + 1 < sel.length && sel[j + 1] == '=' && ['~', '^', '$', '*', '|'].canFind(sel[j]))
               {
                   j++;
               }
               j++;
               if (append(SelectorType.Operator, i, j))
               {
                   continue;
               }
           }

           // Lex pseudo-classes and pseudo-elements
           if (i < sel.length && sel[i] == ':')
           {
               SelectorType t = SelectorType.PseudoClass;
               if (j + 1 < sel.length && sel[j + 1] == ':')
               {
                   t = SelectorType.PseudoElement;
                   j++;
               }
               j++;
               while (j < sel.length &&
                       (
                        sel[j] >= 'A' && sel[j] <= 'Z' ||
                        sel[j] >= 'a' && sel[j] <= 'z' ||
                        sel[j] == '-'
                       )
                     )
               {
                   j++;
               }
               if (append(t, i, j))
               {
                   continue;
               }
           }

           // Lex numbers
           while (j < sel.length && sel[j] >= '0' && sel[j] <= '9')
           {
               j++;
           }
           if (append(SelectorType.Number, i, j))
           {
               continue;
           }
           i++;
        }
        return cleanWhitespace(parts);
    }

    unittest
    {
        with (new HtmlDocument)
        {
            with (SelectorPart.PartType)
            {
                alias SelectorPart p;
                alias Operator op;
                alias Identifier id;
                alias PseudoClass pc;
                alias PseudoElement pe;
                alias Whitespace ws;
                alias String str;
                alias Number num;
                assert(lexSelector(`*`) == [p(op, "*")]);
                assert(lexSelector(`E`) == [p(id, "E")]);
                assert(lexSelector(`E[foo]`) == [p(id, "E"), p(op, "["), p(id, "foo"), p(op, "]")]);
                assert(lexSelector(`E[foo="bar"]`) == [p(id,"E"), p(op, "["), p(id, "foo"), p(op, "="), p(str, "bar"), p(op, "]")]);
                assert(lexSelector(`E[foo~="bar"]`) == [p(id, "E"), p(op, "["), p(id, "foo"), p(op, "~="), p(str, "bar"), p(op, "]")]);
                assert(lexSelector(`E[foo^="bar"]`) == [p(id, "E"), p(op, "["), p(id, "foo"), p(op, "^="), p(str, "bar"), p(op, "]")]); 
                assert(lexSelector(`E[foo$="bar"]`) == [p(id, "E"), p(op, "["), p(id, "foo"), p(op, "$="), p(str, "bar"), p(op, "]")]); 
                assert(lexSelector(`E[foo*="bar"]`) == [p(id, "E"), p(op, "["), p(id, "foo"), p(op, "*="), p(str, "bar"), p(op, "]")]); 
                assert(lexSelector(`E[foo|="bar"]`) == [p(id, "E"), p(op, "["), p(id, "foo"), p(op, "|="), p(str, "bar"), p(op, "]")]); 
                assert(lexSelector(`E:root`) == [p(id, "E"), p(pc, ":root")]);
                assert(lexSelector(`E:nth-child(n)`) == [p(id, "E"), p(pc, ":nth-child"), p(op, "("), p(id, "n"), p(op, ")")]);
                assert(lexSelector(`E:nth-last-child(n)`) == [p(id, "E"), p(pc, ":nth-last-child"), p(op, "("), p(id, "n"), p(op, ")")]);
                assert(lexSelector(`E:first-child`) == [p(id, "E"), p(pc, ":first-child")]);
                assert(lexSelector(`E:empty`) == [p(id, "E"), p(pc, ":empty")]);
                assert(lexSelector(`E:lang(fr)`) == [p(id, "E"), p(pc, ":lang"), p(op, "("), p(id, "fr"), p(op, ")")]);
                assert(lexSelector(`E::first-line`) == [p(id, "E"), p(pe, "::first-line")]);
                assert(lexSelector(`E::before`) == [p(id, "E"), p(pe, "::before")]);
                assert(lexSelector(`E.warning`) == [p(id, "E"), p(op, "."), p(id, "warning")]);
                assert(lexSelector(`E#myid`) == [p(id, "E"), p(op, "#"), p(id, "myid")]);
                assert(lexSelector(`E:not(s)`) == [p(id, "E"), p(pc, ":not"), p(op, "("), p(id, "s"), p(op, ")")]);
                assert(lexSelector(`E F`) == [p(id, "E"), p(ws, " "), p(id, "F")]);
                assert(lexSelector(`E > F`) == [p(id, "E"), p(op, ">"), p(id, "F")]);
                assert(lexSelector(`E + F`) == [p(id, "E"), p(op, "+"), p(id, "F")]);
                assert(lexSelector(`E ~ F`) == [p(id, "E"), p(op, "~"), p(id, "F")]);
                assert(lexSelector(`h1 > F G, E:not( E:nth-child(4) )`) == [p(id, "h1"), p(op, ">"), p(id, "F"), p(ws, " "), p(id, "G"), p(op, ","),
                                                                           p(id, "E"), p(pc, ":not"), p(op, "("), p(id, "E"), p(pc, ":nth-child"),
                                                                           p(op, "("), p(num, "4"), p(op, ")"), p(op, ")")]);
            }
        }
    }

    /**
     * Break a selector string into individual selectors
     *
     * Params:
     *  selector = Lexed selector array from lexSelector()
     * Returns:
     *  Array of individual selectors
     */
    private SelectorPart[][] splitSelectors(SelectorPart[] selector)
    {
        SelectorPart[][] selectors;
        size_t i = 0;
        foreach (j, s; selector)
        {
            if (s.type == SelectorType.Operator && s.value == ",")
            {
                selectors ~= selector[i..j-1];
                i = j + 1;
            }
        }
        if (selectors.length == 0)
        {
            selectors ~= selector;
        }
        return selectors;
    }

    /**
     * Defines the method to use to match elements
     */
    enum FindStyle
    {
        Equal,          // =
        Whitespace,     // ~=
        Start,          // ^=
        End,            // $=
        Any,            // *=
        Hyphen          // |=
    }

    /**
     * Match the needle with the haystack using the given FindStyle
     *
     * Params:
     *  style = Matching style
     *  haystack = String to search
     *  needle = String to match with
     * Returns:
     *  true if the needle and haystack match, false otherwise
     */
    private bool match(FindStyle style, string haystack, string needle)
    {
        switch (style)
        {
            case FindStyle.Equal:
                return haystack == needle;
            case FindStyle.Whitespace:
                // BUG Should support all whitespace, not just space
                auto arr = split(haystack, " ");
                return arr.canFind(needle);
            case FindStyle.Start:
                return haystack.startsWith(needle);
            case FindStyle.End:
                return haystack.endsWith(needle) == 1;
            case FindStyle.Any:
                return haystack.canFind(needle);
            case FindStyle.Hyphen:
                auto arr = split(haystack, "-");
                return arr.canFind(needle);
            default:
                assert(0);
        }
    }

    /**
     * Find an element by its attribute
     *
     * Pass null to ignore the given parameter
     *
     * Params:
     *  el = Name of the element
     *  attr = Name of the attribute
     *  val = Value of the attribute
     *  style = Method to match elements
     * Returns:
     *  Array of matching elements
     */
    private typeof(this)[] findByAttribute(string el, string attr, string val, FindStyle style=FindStyle.Equal)
    {
        typeof(this)[] matches;
        foreach (child; mChildren)
        {
            if ((el is null || el == elementTypeToString(child.mType)) &&
                (val is null && child.getAttribute(attr)) || (child.getAttribute(attr) !is null && match(style, child.getAttribute(attr), val)))
            {
                matches ~= child;
            }
            else if (child.mChildren.length > 0)
            {
                matches = child.findByAttribute(el, attr, val, style);
            }
        }
        return matches;
    }

    /**
     * Find an element in the document, acts as a caching mechanism to prevent
     * re-lexing when recursing into child elements
     *
     * Params:
     *  selectors = Array of selectors
     * Throws:
     *  HtmlDocumentSelectorException on invalid selector
     */
    private typeof(this)[] find(SelectorPart[][] selectors)
    {
        typeof(this)[] matches;
        foreach(selector; selectors)
        {
            if (selector[0].type == SelectorType.Identifier)
            {
                if (!elementList.canFind(fcToUpper(selector[0].value == "body" ? "body_" : selector[0].value)))
                {
                    throw new HtmlDocumentSelectorException(selector[0].value ~ " is not a valid element");
                }
                if (selector.length > 1)
                {
                    if (selector.length == 3 &&
                        selector[1].type == SelectorType.Operator &&
                        selector[2].type == SelectorType.Identifier)
                    {
                        if (selector[1].value == "#")
                        {
                            // E#foobar
                            auto match = findByAttribute(selector[0].value, "id", selector[2].value);
                            if (match.length != 1)
                            {
                                throw new HtmlDocumentSelectorException("Invalid Document, multiple elements with id: " ~ selector[2].value);
                            }
                            matches ~= match[0];
                        }
                        else if (selector[1].value == ".")
                        {
                            // E.foobar
                            matches ~= findByAttribute(selector[0].value, "class", selector[2].value);
                        }
                    }
                    else if (selector.length == 6 &&
                             selector[1].type == SelectorType.Operator &&
                             selector[1].value == "[" &&
                             selector[2].type == SelectorType.Identifier &&
                             selector[3].type == SelectorType.Operator &&
                             selector[4].type == SelectorType.String &&
                             selector[5].type == SelectorType.Operator &&
                             selector[5].value == "]")
                    {
                        switch (selector[3].value)
                        {
                            case "=":
                                    matches ~= findByAttribute(selector[0].value, selector[2].value, selector[4].value);
                                break;
                            case "~=":
                                    matches ~= findByAttribute(selector[0].value, selector[2].value, selector[4].value, FindStyle.Whitespace);
                                break;
                            case "^=":
                                    matches ~= findByAttribute(selector[0].value, selector[2].value, selector[4].value, FindStyle.Start);
                                break;
                            case "$=":
                                    matches ~= findByAttribute(selector[0].value, selector[2].value, selector[4].value, FindStyle.End);
                                break;
                            case "*=":
                                    matches ~= findByAttribute(selector[0].value, selector[2].value, selector[4].value, FindStyle.Any);
                                break;
                            case "|=":
                                    matches ~= findByAttribute(selector[0].value, selector[2].value, selector[4].value, FindStyle.Hyphen);
                                break;
                            default:
                                throw new HtmlDocumentSelectorException("Invalid operator: " ~ selector[3].value);
                        }
                    }
                }
                else
                {
                    // E
                    if (selector[0].value == elementTypeToString(mType))
                    {
                        matches ~= this;
                    }
                    foreach (child; mChildren)
                    {
                        matches ~= child.find(selectors);
                    }
                }
            }
            else if (selector[0].type == SelectorType.Operator)
            {
                switch (selector[0].value)
                {
                    // #foobar
                    case "#":
                        if (selector[1].type == SelectorType.Identifier)
                        {
                            auto match = findByAttribute(null, "id", selector[1].value);
                            if (match.length != 1)
                            {
                                throw new HtmlDocumentSelectorException("Invalid Document, multiple elements with id: " ~ selector[1].value);
                            }
                            matches ~= match[0];
                        }
                        break;
                    // .foobar
                    case ".":
                        if (selector[1].type == SelectorType.Identifier)
                        {
                            matches ~= findByAttribute(null, "class", selector[1].value);
                        }
                        break;
                    case ">":
                        if (selector[1].type == SelectorType.Operator && selector[1].value == "*")
                        {
                            // > *
                            matches ~= mChildren;
                        }
                        else
                        {
                            // > foobar
                            matches ~= find([selector[1..$]]);
                        }
                        break;
                    case "+":
                        break;
                    case "~":
                        break;
                    case "*":
                        // *
                        if (mChildren.length == 0)
                        {
                            matches = [this];
                        }
                        else
                        {
                            foreach (child; mChildren)
                            {
                                matches ~= child.find([selector]);
                            }
                        }
                        break;
                    default:
                        throw new HtmlDocumentSelectorException("Invalid selector string");
                }
            }
        }
        return matches;
    }

    unittest
    {
        auto b = (new HtmlDocument).body_();
        auto pMonkey = b.p.attr("id", "monkey").content = "monkey";
        auto divChicken = b.div.attr("id", "chicken").content = "chicken";
        auto divPig = b.div.attr("id", "pig");
        auto spanEagle = divPig.span.attr("id", "eagle").attr("class", "bird");
        auto spanPidgeon = divPig.span.attr("id", "pidgeon").attr("class", "bird");
        auto spanMagpie = divPig.span.attr("id", "magpie").attr("class", "bird animal");
        auto spanOsprey = divPig.span.attr("id", "osprey").attr("class", "bird-animal");
        assert(b.find("> *") == [pMonkey, divChicken, divPig]);
        assert(b.find("> #pig") == [divPig]);
        assert(b.find("> div#pig") == [divPig]);
        assert(divPig.find(".bird") == [spanEagle, spanPidgeon]);
        assert(b.find("span.bird") == [spanEagle, spanPidgeon]);
        assert(b.find(`span[class="bird"]`) == [spanEagle, spanPidgeon]);
        assert(b.find(`span[class^="bir"]`) == [spanEagle, spanPidgeon, spanMagpie, spanOsprey]);
        assert(b.find(`span[class$="ird"]`) == [spanEagle, spanPidgeon]);
        assert(b.find(`span[class*="ird"]`) == [spanEagle, spanPidgeon, spanMagpie, spanOsprey]);
        assert(b.find(`span[class*="ir"]`) == [spanEagle, spanPidgeon, spanMagpie, spanOsprey]);
        assert(b.find(`span[class~="animal"]`) == [spanMagpie]);
        assert(b.find(`span[class~="bird"]`) == [spanEagle, spanPidgeon, spanMagpie]);
        assert(b.find(`span[class|="bird"]`) == [spanEagle, spanPidgeon, spanOsprey]);
        assert(b.find(`span[class|="animal"]`) == [spanOsprey]);
        //assert(spanPidgeon.find(`:root`) == [b.parent]);
        // TODO Add tests for all of the below + those in spec, check coverage
        // TODO Test myElement.find("some selector string that should find myElement")
        //assert();
/*                assert(lexSelector(`*`) == [p(op, "*")]);
                assert(lexSelector(`E`) == [p(id, "E")]);
                assert(lexSelector(`E[foo]`) == [p(id, "E"), p(op, "["), p(id, "foo"), p(op, "]")]);
                assert(lexSelector(`E:root`) == [p(id, "E"), p(pc, ":root")]);
                assert(lexSelector(`E:nth-child(n)`) == [p(id, "E"), p(pc, ":nth-child"), p(op, "("), p(id, "n"), p(op, ")")]);
                assert(lexSelector(`E:nth-last-child(n)`) == [p(id, "E"), p(pc, ":nth-last-child"), p(op, "("), p(id, "n"), p(op, ")")]);
                assert(lexSelector(`E:first-child`) == [p(id, "E"), p(pc, ":first-child")]);
                assert(lexSelector(`E:empty`) == [p(id, "E"), p(pc, ":empty")]);
                assert(lexSelector(`E:lang(fr)`) == [p(id, "E"), p(pc, ":lang"), p(op, "("), p(id, "fr"), p(op, ")")]);
                assert(lexSelector(`E::first-line`) == [p(id, "E"), p(pe, "::first-line")]);
                assert(lexSelector(`E::before`) == [p(id, "E"), p(pe, "::before")]);
                assert(lexSelector(`E.warning`) == [p(id, "E"), p(op, "."), p(id, "warning")]);
                assert(lexSelector(`E#myid`) == [p(id, "E"), p(op, "#"), p(id, "myid")]);
                assert(lexSelector(`E:not(s)`) == [p(id, "E"), p(pc, ":not"), p(op, "("), p(id, "s"), p(op, ")")]);
                assert(lexSelector(`E F`) == [p(id, "E"), p(ws, " "), p(id, "F")]);
                assert(lexSelector(`E > F`) == [p(id, "E"), p(op, ">"), p(id, "F")]);
                assert(lexSelector(`E + F`) == [p(id, "E"), p(op, "+"), p(id, "F")]);
                assert(lexSelector(`E ~ F`) == [p(id, "E"), p(op, "~"), p(id, "F")]);
                assert(lexSelector(`h1 > F G, E:not( E:nth-child(4) )`) == [p(id, "h1"), p(op, ">"), p(id, "F"), p(ws, " "), p(id, "G"), p(op, ","),
                                                                           p(id, "E"), p(pc, ":not"), p(op, "("), p(id, "E"), p(pc, ":nth-child"),
                                                                           p(op, "("), p(num, "4"), p(op, ")"), p(op, ")")]);*/
    }

    /**
     * Find an element in the document
     *
     * This supports all CSS selectors that make sense to support, as well as
     * a special case for "> F", "+ F" and "~ F" meaning that the current
     * element is used as E.
     *
     * Params:
     *  selString = CSS-style selector string
     * Returns:
     *  Array of matching elements
     * Examples:
     *  ----
     *  find("body")[0]; // Body element
     *  find("div#monkey")[0]; // Div with id monkey
     *  find("span.ner"); // Array of all span elements with the class ner
     *  find("> *"); // Array of all child elements
     *  ----
     * See_Also:
     *   - http://www.w3.org/TR/CSS2/selector.html
     *   - http://www.w3.org/TR/css3-selectors/#selectors
     * Throws:
     *  HtmlDocumentSelectorException on invalid selector string
     */
    public typeof(this)[] find(string selString)
    {
        auto selectors = splitSelectors(lexSelector(selString));
        return find(selectors);
    }

    mixin(genElMethods());
}

