/**
 * Serenity Web Framework
 *
 * Layout.d: Wrap a controllers output in a layout
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Layout;

public import serenity.Controller;
public import serenity.Document;
import serenity.Log;
import serenity.Util;

template registerLayout(T)
{
    static this()
    {
        // TODO: This should be static, blame dmd >.>
        // See: http://d.puremagic.com/issues/show_bug.cgi?id=4033
        //assert(isDerived(T.classinfo, Layout.classinfo));
        Layout.register(T.classinfo);
    }
}

mixin SerenityException!("InvalidLayout");

class Layout
{
    private static ClassInfo[string] mLayouts;


    /**
     * Layout the given controller and document
     *
     * Params:
     *  main = The main controller, as specified by the router
     *  doc  = The document returned from main.view()
     * Returns:
     *  The resulting document, with a layout specified in the subclass
     */
    abstract public Document layout(Controller main, Document doc);

    /**
     * Create a layout from the given plugin with the given name
     *
     * Params:
     *  plugin = Name of the plugin in which the Layout resides
     *  name   = Name of the layout
     * Throws:
     *  InvalidLayoutException when the given Layout does not exist
     * Returns:
     *  The specified layout
     */
    public static Layout create(string plugin, string name)
    {
        auto cname = plugin ~ ".layouts." ~ name ~ "." ~ name;
        auto registered = cname in mLayouts;
        if (registered is null)
        {
            throw new InvalidLayoutException("Invalid layout: " ~ cname);
        }
        return cast(typeof(this))registered.create();
    }

    /**
     * Register the given layout
     *
     * This should not be called directly, this is handled by registerLayout!(T)
     * Params:
     *  ci = ClassInfo of the layout to register
     * Throws:
     *  InvalidLayoutException when the given layout does not extend
     *  Layout
     */
    public static void register(ClassInfo ci)
    {
        /*if (!isDerived(ci, this.classinfo))
        {
            throw new InvalidLayoutException("Invalid layout: " ~ ci.name);
        }*/
        mLayouts[ci.name] = ci;
    }
}
