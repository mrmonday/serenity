/**
 * Serenity Web Framework
 *
 * Model.d: Base class for models in Serenity
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Model;

import serenity.Log;

public import serenity.Database : Result;
public import serenity.SqlQuery;

abstract class Model
{
    private Logger mLog;

    /**
     * Return the logger for the current model
     *
     * Examples:
     * ----
     *  void myMethod()
     *  {
     *      if (log.info) log.info("myMethod()");
     *  }
     * ----
     * Returns:
     *  Instance of Logger for the current model
     */
    protected Logger log()
    {
        if (mLog is null)
        {
            mLog = Log.getLogger(this.classinfo.name);
        }
        return mLog;
    }

    abstract public void create();
}
