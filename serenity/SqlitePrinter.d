/**
 * Serenity Web Framework
 *
 * SqlitePrinter.d: Print an SqlQuery in a valid form for SQLite databases
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.SqlitePrinter;
version(none):
public import serenity.SqlPrinter;

class SqlitePrinter : SqlPrinter
{
    override void print(Query doc, void delegate(string[]...) dg)
    {
        switch (doc.getType())
        {
            case QueryType.Select:
                    dg("SELECT ");
                    auto columns = doc.getColumns();
                    if (columns.length == 1 && columns[0] == "*")
                    {
                        dg("*");
                    }
                    else
                    {
                        foreach (i, column; columns)
                        {
                            dg("`", column, "`");
                            if (i != columns.length - 1)
                            {
                                dg(", ");
                            }
                        }
                    }
                    dg(" FROM `", doc.tableName(), "`");
                    auto wheres = doc.getWhereClauses();
                    if (wheres.length > 0)
                    {
                        dg(" WHERE ");
                        foreach (i, where; wheres)
                        {
                            dg(where);
                            if (i != wheres.length - 1)
                            {
                                dg(" AND ");
                            }
                        }
                    }
                    dg(";");
                break;
            case QueryType.Insert:
                dg("INSERT INTO `", doc.tableName(), "`");
                auto columns = doc.getColumns();
                if (columns.length > 0)
                {
                    dg(" (");
                    foreach (i, column; columns)
                    {
                        dg("`", column, "`");
                        if (i != columns.length - 1)
                        {
                            dg(", ");
                        }
                    }
                    dg(")");
                }
                dg(" VALUES(");
                auto values = doc.getValues();
                foreach (i, value; values)
                {
                    if (value.isFunction)
                    {
                        switch (value.func.name)
                        {
                            case Function.Now:
                                dg(`strftime('%Y-%m-%dT%H:%M:%S', 'now')`);
                                break;
                            default:
                                throw new SqlPrinterException("Unsupported function for SQLite");
                        }
                    }
                    else
                    {
                        if (value.value == "?")
                        {
                            dg("?");
                        }
                        else
                        {
                            dg("'", value.value, "'");
                        }
                    }
                    if (i != values.length - 1)
                    {
                        dg(", ");
                    }
                }
                dg(");");
                break;
            case QueryType.CreateTable:
                foreach (table; doc.getTables())
                {
                   dg("CREATE TABLE IF NOT EXISTS `", table.getName(), "` (");
                   auto fields = table.getFields();
                   foreach (i, field; fields)
                   {
                       dg("`", field.name, "` ");
                       switch (field.type)
                       {
                           case Type.Bool:
                           case Type.Byte:
                           case Type.Ubyte:
                           case Type.Short:
                           case Type.Ushort:
                           case Type.Int:
                           case Type.Uint:
                           case Type.Long:
                           case Type.Ulong:
                               dg("INTEGER");
                               break;
                           case Type.Float:
                           case Type.Double:
                               dg("REAL");
                               break;
                           case Type.String:
                           case Type.Wstring:
                           case Type.Time:
                               dg("TEXT");
                               break;
                           case Type.UbyteArr:
                               dg("BLOB");
                               break;
                           default:
                               throw new SqlPrinterException("Unsupported datatype for SQLite");
                       }
                       if (field.constraints != None)
                       {
                           if (field.constraints & NotNull)
                           {
                               dg(" NOT NULL");
                           }
                           if (field.constraints & Unique)
                           {
                               dg(" UNIQUE");
                           }
                           if (field.constraints & PrimaryKey)
                           {
                               dg(" PRIMARY KEY");
                               if (field.constraints & AutoIncrement)
                               {
                                   dg(" AUTOINCREMENT");
                               }
                           }
                           // TODO
                           /*if (field.constraints & ForeignKey)
                           {
                               assert(0);
                           }*/
                           if (field.constraints & Check)
                           {
                               assert(0);
                           }
                          /* if (field.constraints & Default)
                           {
                               assert(0);
                           }*/
                       }
                       if (i != fields.length - 1)
                       {
                           dg(", ");
                       }
                   }
                   dg(");");
                }
                break;
            default:
                assert(false, "Query type unimplemented for SQLite");
        }
    }

    unittest
    {
        with (new typeof(this))
        {
            auto doc = new SqlQuery;
            doc.select("*").from("table").where("`column` = 'value'").where("column2 >= 7");
            assert(getQueryString(doc) == "SELECT * FROM `table` WHERE `column` = 'value' AND column2 >= 7;");

            doc = new SqlQuery;
            doc.select("a", "b", "c").from("table");
            assert(getQueryString(doc) == "SELECT `a`, `b`, `c` FROM `table`;");

            doc = new SqlQuery;
            doc.insert.into("table").values(1, "2", 3, "?");
            assert(getQueryString(doc) == "INSERT INTO `table` VALUES('1', '2', '3', ?);");

            doc = new SqlQuery;
            doc.insert.into("table", "col1", "col2", "a", "b").values(1, "2", 3, "?");
            assert(getQueryString(doc) == "INSERT INTO `table` (`col1`, `col2`, `a`, `b`) VALUES('1', '2', '3', ?);");

            struct Test
            {
                int id;
                string text;
                ubyte[] content;
            }
            doc = new SqlQuery;
            doc.createTable("foo").bind!(Test)(NotNull).field("id", PrimaryKey | AutoIncrement);
            assert(getQueryString(doc) == "CREATE TABLE IF NOT EXISTS `foo` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `text` TEXT NOT NULL, `content` BLOB NOT NULL);");
        }
    }
}
