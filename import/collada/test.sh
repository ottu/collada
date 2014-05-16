#!/bin/bash
dmd $1 -main -unittest -debug -g \
    -I../../import \
    -I~/.dub/packages/gl3n-master/import \
    -I~/.dub/packages/kxml-master/source \
    -I~/.dub/packages/derelict-master/import \
    base.d \
    utils.d \
    ~/.dub/packages/gl3n-master/lib/libgl3n-dmd.a \
    ~/.dub/packages/derelict-master/lib/dmd/libDerelictFI.a \
    ~/.dub/packages/derelict-master/lib/dmd/libDerelictGL3.a \
    ~/.dub/packages/derelict-master/lib/dmd/libDerelictGLFW3.a \
    ~/.dub/packages/derelict-master/lib/dmd/libDerelictUtil.a \
    ~/.dub/packages/kxml-master/libkxml.a
