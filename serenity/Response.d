/**
 * Serenity Web Framework
 *
 * Response.d: Represents a response to a request
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2010, 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.Response;

import serenity.HtmlDocument;
import serenity.HtmlPrinter;
import serenity.Request;
import serenity.Util;

import std.stream;
import std.string;

mixin SerenityException!("Response");

private string[ushort] statusCodes;

static this()
{
    // This should be constant. Grr dmd.
    statusCodes =   [
                        100 : "100 Continue",
                        101 : "101 Switching Protocols",
                        200 : "200 OK",
                        201 : "201 Created",
                        202 : "202 Accepted",
                        203 : "203 Non-Authoritative Information",
                        204 : "204 No Content",
                        205 : "205 Reset Content",
                        206 : "206 Partial Content",
                        300 : "300 Multiple Choices",
                        301 : "301 Moved Permanently",
                        302 : "302 Found",
                        303 : "303 See Other",
                        304 : "304 Not Modified",
                        305 : "305 Use Proxy",
                        307 : "307 Temporary Redirect",
                        400 : "400 Bad Request",
                        401 : "401 Unauthorized",
                        402 : "402 Payment Required",
                        403 : "403 Forbidden",
                        404 : "404 Not Found",
                        405 : "405 Method Not Allowed",
                        406 : "406 Not Acceptable",
                        407 : "407 Proxy Authentication Required",
                        408 : "408 Request Timeout",
                        409 : "409 Conflict",
                        410 : "410 Gone",
                        411 : "411 Length Required",
                        412 : "412 Precondition Failed",
                        413 : "413 Request Entity Too Large",
                        414 : "414 Request-URI Too Long",
                        415 : "415 Unsupported Media Type",
                        416 : "416 Requested Range Not Satisfiable",
                        417 : "417 Expectation Failed",
                        500 : "500 Internal Server Error",
                        501 : "501 Not Implemented",
                        502 : "502 Bad Gateway",
                        503 : "503 Service Unavailable",
                        504 : "504 Gateway Timeout",
                        505 : "505 HTTP Version Not Supported"
                    ];
}

class Response
{
    private Request         mRequest;
    private string[string]  mHeaders;
    private Document        mDocument;
    private ushort          mCode;

    this(Request req, string[string] headers, Document doc, ushort code)
    {
        mRequest = req;
        mHeaders = headers;
        mDocument = doc is null ? new HtmlDocument : doc;
        mCode = code;
    }

    /**
     * Send the HTTP response code to the given FormatOutput!(char)
     *
     * Params:
     *  stdout = The place to send the response
     */
    private void sendStatus(OutputStream stdout)
    {
        auto code = mCode in statusCodes;
        if (code is null)
        {
            throw new ResponseException("Invalid status code: " ~ cast(char)(mCode+48)); 
        }
        stdout.write("Status: "c);
        stdout.write(*code);
        stdout.write("\r\n"c);
    }

    /**
     * Send the response to the given FormatOutput!(char)
     *
     * Params:
     *  stdout = The place to send the response
     */
    public void send(OutputStream stdout)
    {
       auto printer = mRequest.protocol() & Request.Protocol.Cli ? new HtmlPrinter()  : new HtmlPrinter();
       sendStatus(stdout);
       foreach (header, value; mHeaders)
       {
           stdout.write(header);
           stdout.write(": "c);
           stdout.write(value);
           stdout.write("\r\n"c);
       }
       stdout.write("\r\n"c);
       printer.print(cast(HtmlDocument)mDocument, (string[] strs...) { foreach (str; strs) stdout.write(str); });
       if (mRequest.protocol & Request.Protocol.Cli)
       {
           stdout.write("\r\n"c);
       }
    }
}
