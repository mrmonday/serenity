/**
 * Serenity Web Framework
 *
 * bindings/FastCGI.d: Bindings for FastCGI
 *
 * Authors: Robert Clipsham <robert@octarineparrot.com>
 * Copyright: Copyright (c) 2011, Robert Clipsham <robert@octarineparrot.com> 
 * License: New BSD License, see COPYING
 */
module serenity.bindings.FastCGI;

extern(C):

struct FCGX_Stream {
    ubyte* rdNext;   
    ubyte* wrNext;
    ubyte* stop; 
    ubyte* stopUnget; 
    int isReader;
    int isClosed;
    int wasFCloseCalled;
    int FCGI_errno;                
    void* function(FCGX_Stream* stream) fillBuffProc;
    void* function(FCGX_Stream* stream, int doClose) emptyBuffProc;
    void* data;
}

alias char** FCGX_ParamArray;

int FCGX_Accept(FCGX_Stream** stdin, FCGX_Stream** stdout, FCGX_Stream** stderr, FCGX_ParamArray* envp);
int FCGX_GetChar(FCGX_Stream* stream);
int FCGX_PutStr(const char* str, int n, FCGX_Stream* stream);
int FCGX_HasSeenEOF(FCGX_Stream* stream);
