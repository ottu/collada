module collada.model;

import std.stdio;
import std.algorithm;
import std.range;
import std.array;
import std.math;
import std.string : toStringz;
import std.parallelism;
//import std.windows.charset;

import collada.collada;
import collada.base;
import collada.dataflow;
import collada.geometry;
import collada.image;
import collada.effect;
import collada.material;
import collada.controller;
import collada.instance;
import collada.scene;
import collada.transform;
import collada.animation;
import collada.modelutils;

import adjustxml;

import opengl.gl;
import opengl.glu;
import opengl.glfw;

import derelict.devil.il;
import derelict.devil.ilu;

float[16] transpose( float[] matrix )
{
    assert( matrix.length == 16 );
    return [ matrix[0], matrix[4], matrix[8],  matrix[12], 
             matrix[1], matrix[5], matrix[9],  matrix[13], 
             matrix[2], matrix[6], matrix[10], matrix[14], 
             matrix[3], matrix[7], matrix[11], matrix[15] ];
}

void multr( ref float[4] v1, ref const float[16] v2 )
{
    float v10 = v1[0];
    float v11 = v1[1];
    float v12 = v1[2];
    float v13 = v1[3];
    
    v1[0] = v10*v2[0] + v11*v2[4] + v12*v2[8]  + v13*v2[12];
    v1[1] = v10*v2[1] + v11*v2[5] + v12*v2[9]  + v13*v2[13];
    v1[2] = v10*v2[2] + v11*v2[6] + v12*v2[10] + v13*v2[14];
    v1[3] = v10*v2[3] + v11*v2[7] + v12*v2[11] + v13*v2[15];
}

template isPermitted(T)
{
    enum bool isPermitted = ( is(T==float) || is(T==int) || is(T==bool) || is(T==string) );
}

struct WrappedSource(T) if ( isPermitted!T )
{
    alias T type;
    Source _self;

    string id;
    
    struct InnerArray
    {
        string aid;
        T[] _init;
        
        this(TypeArray!T typeArray)
        {
            aid = typeArray.id;
            _init  = typeArray.dup;
        }
    }
    InnerArray _array;
    
    
    struct BW
    {
        WrappedBone* _bone;
        float _weight;
    }
    struct InnerParam
    {
        T[] _value;
        T[] _writeValue;
        
        T*[][] _triRefs;
        BW[] _bwRefs;
        
        static if( is( T == float ) )
        {    
        float[4] __vertex;
        float[4] __v;
        void calc()
        {
            
            __vertex[0] = 0.0;
            __vertex[1] = 0.0;
            __vertex[2] = 0.0;
            __vertex[3] = 0.0;
            
            for( int i = 0; i < _bwRefs.length; ++i )
            {
                
                __v[0] = _value[0];
                __v[1] = _value[1];
                __v[2] = _value[2];
                __v[3] = 1.0;
                
                multr( __v, _bwRefs[i]._bone.matrix );
                //multr( __v, _bwRefs[i]._bone.pp );
                multr( __v, _bwRefs[i]._bone.pose );
                
                auto p = _bwRefs[i]._bone.parent;
                while( p != null )
                {
                    multr( __v, p.pose );
                    p = p.parent;
                }
                
                __v[0] = __v[0] * _bwRefs[i]._weight;
                __v[1] = __v[1] * _bwRefs[i]._weight;
                __v[2] = __v[2] * _bwRefs[i]._weight;
                
                __vertex[0] = __vertex[0] + __v[0];
                __vertex[1] = __vertex[1] + __v[1];
                __vertex[2] = __vertex[2] + __v[2];
                
            }
            
            for( int j = 0; j < _triRefs.length; ++j )
            {
                *(_triRefs[j][0]) = __vertex[0];
                *(_triRefs[j][1]) = __vertex[1];
                *(_triRefs[j][2]) = __vertex[2];
            }
            
        }
        
        }
    }
    InnerParam[] _accessor;
    
    static if( is( T == float ) )
    void calc()
    {
        foreach( ref param; taskPool.parallel( _accessor ) )
        //foreach( ref param; _accessor )
            param.calc();
    }

    this( Source source )
    {
        _self = source;
        id = source.id;
        static if( is( T == string ) )
        {
            assert( source.type == ARRAYTYPE.NAME );
            _array = InnerArray( source.nameArray );
        }
        else static if( is( T == float ) )
        {
            assert( source.type == ARRAYTYPE.FLOAT );
            _array = InnerArray( source.floatArray );
        }
        else static if( is( T == int ) )
        {
            assert( source.type == ARRAYTYPE.INT );
            _array = InnerArray( source.intArray );
        }
        else static if( is( T == bool ) )
        {
            assert( source.type == ARRAYTYPE.BOOL );
            _array = InnerArray( source.boolArray );
        }
        else static if( true )
        {
            throw new Exception("dame!"); 
        }
        
        _accessor.length = _self.common.accessor.count;
        uint stride = _self.common.accessor.stride;
        for( int i = 0; i < _self.common.accessor.count; ++i )
        {
            uint start = i*stride;
            uint end   = start+stride;
            _accessor[i]._value = _array._init[ start..end ];
        }
        
    }
}

auto wrapSource(T)( Source source ) if ( isPermitted!T )
{
    return WrappedSource!T(source);
}

unittest
{
    Source source;
    source.load( parseXML( q{
        <source id="Position">
          <float_array id="Position-Array" count="9"> 1 2 3 4 5 6 7 8 9 </float_array>
          <technique_common>
            <accessor source="#Position-Array" count="3" stride="3">
              <param type="float" name="X" />
              <param type="float" name="Y" />
              <param type="float" name="Z" />
            </accessor>
          </technique_common>
        </source>
    } ).root );
    
    auto wSource = source.wrapSource!float;
    assert( wSource._array._init == [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] );
    assert( wSource._accessor[0]._value == [1,2,3] );
    assert( wSource._accessor[1]._value == [4,5,6] );
    assert( wSource._accessor[2]._value == [7,8,9] );
        
}

struct WrappedInputB(T) if ( is(T==float) || is(T==int) || is(T==bool) )
{
    InputB _self;

    T[] _init;
    T[] _values;
    alias _values this;

    this( InputB input, uint[] indices, WrappedSource!(T)* wsource )
    {
        assert( input.source[1..$] == wsource.id );

        _self = input;
        
        foreach( i; indices )
            _init ~= wsource._accessor[i]._value;
        
        if( _self.semantic == SEMANTICTYPE.TEXCOORD )
        {
            //PMDはコメントアウト
            //PMXはコメントアウト外す
            for( int i = 1; i < _init.length; i += 2 )
                _init[i] *= -1;
        }
        
        _values = _init.dup;
        
        int count = 0;
        foreach( i; indices )
            wsource._accessor[i]._triRefs ~= _self.semantic == SEMANTICTYPE.TEXCOORD 
                                            ? [ &(_values[count++]), &(_values[count++]) ]
                                            : [ &(_values[count++]), &(_values[count++]), &(_values[count++]) ];

    }

    void init()
    {
        assert( _values.length == _init.length );
        for( int i = 0; i < _init.length; ++i )
            _values[i] = _init[i];
    }
}

auto wrapInputB(T)( InputB input, uint[] indexes, WrappedSource!(T)* wsource ) 
                if ( is(T==float) || is(T==int) || is(T==bool) )
{
    return WrappedInputB!T( input, indexes, wsource );
}

struct WrappedTriangles(T) if ( is(T==float) || is(T==int) )
{
    Triangles _self;

    WrappedInputB!(T)[] _inputs;
    //alias _inputs this;

    this( Triangles triangles, WrappedSource!(T)[] wsources )
    {
        _self = triangles;

        uint[][] indices;
        indices.length = _self.inputs.length;
        
        foreach( i, index; _self.p )
            indices[ i % _self.inputs.length ] ~= index;
        
        foreach( input; _self.inputs )
            _inputs ~= wrapInputB!T( input, indices[input.offset],
                                    &(filter!( (ref wsource) => input.source[1..$] == wsource.id )
                                           ( wsources[] ).array[0] ) );

       writefln( "Trialnges [%s] loaded!", _self.material );
    }

    void load( bool enableTexture = true )
    {
        //glPolygonMode(GL_FRONT_AND_BACK, enableTexture ? GL_FILL : GL_LINE );
        //glPolygonMode(GL_FRONT, enableTexture ? GL_FILL : GL_LINE );
        if( enableTexture )
            glPolygonMode( GL_FRONT, GL_FILL );
        else
            glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
        
        glEnableClientState( GL_VERTEX_ARRAY );
        glEnableClientState( GL_NORMAL_ARRAY );
        glEnableClientState( GL_TEXTURE_COORD_ARRAY );
        
        glVertexPointer( 3, GL_FLOAT, 0, _inputs[0]._values.ptr );
        glNormalPointer( GL_FLOAT, 0, _inputs[1]._values.ptr );
        glTexCoordPointer( 2, GL_FLOAT, 0, _inputs[2]._values.ptr );
        
        glDrawArrays( GL_TRIANGLES, 0, 3*_self.count );

        glDisableClientState( GL_TEXTURE_COORD_ARRAY );
        glDisableClientState( GL_NORMAL_ARRAY );
        glDisableClientState( GL_VERTEX_ARRAY );
    }
}

auto wrapTriangles(T)( Triangles triangles, ref WrappedSource!(T)[] wsources )
                    if ( is(T==float) || is(T==int) )
{
    return WrappedTriangles!T( triangles, wsources );
}

unittest
{
    Source source;
    source.load( parseXML( q{
        <source id="Position">
          <float_array id="Position-Array" count="18"> 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 </float_array>
          <technique_common>
            <accessor source="#Position-Array" count="6" stride="3">
              <param type="float" name="X" />
              <param type="float" name="Y" />
              <param type="float" name="Z" />
            </accessor>
          </technique_common>
        </source>
    } ).root );
    
    auto wSource = source.wrapSource!float;
    
    WrappedSource!(float)[] wSources;
    wSources ~= wSource;

    Triangles tri;
    tri.load( parseXML( q{
        <triangles count="3" material="Symbol">
          <input semantic="VERTEX" source="#Position" offset="0" />
          <p> 0 3 4 4 1 0 1 4 5 </p>
        </triangles>
    } ).root );
    
    auto wTri = tri.wrapTriangles!float( wSources );
    
    assert( wTri._inputs[0]._init == [  0, 1, 2,  9,10,11, 12,13,14,
                                       12,13,14,  3, 4, 5,  0, 1, 2,
                                        3, 4, 5, 12,13,14, 15,16,17 ] );
    assert( wTri._inputs[0]._values == [  0, 1, 2,  9,10,11, 12,13,14,
                                         12,13,14,  3, 4, 5,  0, 1, 2,
                                          3, 4, 5, 12,13,14, 15,16,17 ] );
    
}

struct WrappedMesh(T) if ( is(T==float) || is(T==int) )
{
    Mesh _self;
    
    WrappedSource!(T)[]    _wsources;
    WrappedSource!(T)*     _vertices;
    WrappedTriangles!(T)[] _wtriangles;
    alias _wtriangles this;
    
    this( Mesh mesh )
    {
        writeln( "Mesh loading..." );
    
        _self = mesh;
        
        auto wss = _self.sources.map!( (a) => a.wrapSource!T ).array;
        foreach( ref ws; wss )
        {
            if( _self.vertices.inputs[0].source[1..$] != ws.id ) continue;
            ws.id = _self.vertices.id;
            _vertices = &ws;
        }
        
        _wsources = wss;
        
        _wtriangles = _self.triangles.map!( (a) => a.wrapTriangles!T( _wsources ) ).array;
        
        writeln( "done!" );
    }
}

auto wrapMesh(T)( Mesh mesh ) if ( is(T==float) || is(T==int) )
{
    return WrappedMesh!T( mesh );
}

struct WrappedGeometry
{
    Geometry _self;
    
    string id;
    WrappedMesh!float mesh;
    
    this( Geometry geometry )
    {
        _self = geometry;
        
        id = geometry.id;
        
        assert( geometry.type == GEOMETRYTYPE.MESH );
        mesh = geometry.mesh.wrapMesh!float;
    }
}

auto wrapGeometry( Geometry geometry )
{
    return WrappedGeometry( geometry );
}

struct WrappedGeometries
{
    LibraryGeometries _self;
    
    WrappedGeometry[] _geometries;
    alias _geometries this;
    
    this( LibraryGeometries libGeometries )
    {
        _self = libGeometries;
        
        _geometries = array( map!( (a) => a.wrapGeometry )( libGeometries.geometries ) );
    }
}

auto wrapGeometries( LibraryGeometries libGeometries )
{
    return WrappedGeometries( libGeometries );
}

struct WrappedImage
{
    Image _self;

    string id;

    ILuint _imageID;
    GLuint _textureID;
    alias _textureID this;

    this( Image image, string path = "" )
    {
        _self = image;
        
        id = _self.id;
        
        ilGenImages( 1, &_imageID );
        ilBindImage( _imageID );
        if( ilLoadImage( (path ~ "/" ~ _self.initFrom).toStringz ) )
        {
            writefln("Image [%s] is loaded!", _self.initFrom );
            //if (!ilConvertImage(IL_RGBA, IL_UNSIGNED_BYTE))    writeln("convert failed!");
            glGenTextures( 1, &_textureID ); 
            glBindTexture( GL_TEXTURE_2D, _textureID ); 
        }
        else
        {
            auto err = ilGetError();
            writefln( "Error! : %d %s", err, iluErrorString(err) );
        }
    }

    void release()
    {
        writefln( "Image [%s] release.", _self.initFrom );
        glDeleteTextures( 1, &_textureID );
        ilDeleteImages( 1, &_imageID );
    }

    void bind()
    {
        ilBindImage( _imageID );
        glBindTexture( GL_TEXTURE_2D, _textureID ); 
    }

}

auto wrapImage( Image image, string path = "" )
{
    return WrappedImage( image, path );
}

struct WrappedImages
{
    LibraryImages _self;
    WrappedImage[] _images;
    alias _images this;
    
    this( LibraryImages libImages, string path = "" )
    {
        writeln("Images loading...");
        
        _self = libImages;
        
        _images = array( map!( (a) => a.wrapImage( path ) )( libImages.images ) );
        
        writeln("done!");
    }
}

auto wrapImages( LibraryImages libImages, string path = "" )
{
    return WrappedImages( libImages, path );
}

struct WrappedEffect
{
    Effect _self;

    string id;

    float[4] _ambient;
    float[4] _specular;
    float    _shininess;
    //diffuse type
    COLORTEXTURETYPE type;
    
    //type == COLOR
    float[4] _color;
    
    //type == TEXTURE
    //string texcoord    
    int _minfilter;
    int _magfilter;
    //source    
    int _format;
    WrappedImage* _initFrom;

    this( Effect effect, WrappedImages* wimages )
    {
        
        _self = effect;
        
        id = effect.id;
        
        assert( _self.profiles[0].type == PROFILETYPE.COMMON );
        assert( _self.profiles[0].common.technique.type == SHADERELEMENTTYPE.PHONG );
        
        Phong phong = _self.profiles[0].common.technique.phong;        
        _ambient   = phong.ambient.color;
        _specular  = phong.specular.color;
        _shininess = phong.shininess.float_[0];
        
        type = phong.diffuse.type;
        
        if( type == COLORTEXTURETYPE.TEXTURE )
        {
            //assert( phong.diffuse.type == COLORTEXTURETYPE.TEXTURE );
            
            NewParamCOMMON sampler = array( filter!( (a) => a.sid == phong.diffuse.texture.texture )( _self.profiles[0].common.newparams ) )[0];
            
            assert( sampler.type == NEWPARAMTYPE.SAMPLER2D );
            assert( sampler.sampler2d.minfilter == "LINEAR_MIPMAP_LINEAR" );
            _minfilter = GL_LINEAR_MIPMAP_LINEAR;
            assert( sampler.sampler2d.magfilter == "LINEAR" );
            _magfilter = GL_LINEAR;
            
            
            NewParamCOMMON surface = array( filter!( (a) => a.sid == sampler.sampler2d.source )( _self.profiles[0].common.newparams ) )[0];
            
            assert( surface.type == NEWPARAMTYPE.SURFACE );
            assert( surface.surface.type == SURFACETYPE.TWOD );
            assert( surface.surface.format == "A8R8G8B8" );
            _format = GL_RGBA8;
            
            _initFrom = &( array( filter!( (ref a) => a.id == surface.surface.initFrom )( (*wimages)[] ) )[0] );
            assert( _initFrom._self.type == IMAGETYPE.INITFROM );
            
            _initFrom.bind;
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR ); 
            //glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _minfilter ); 
            glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _magfilter );         
            glTexImage2D( GL_TEXTURE_2D, 0, ilGetInteger(IL_IMAGE_BPP), ilGetInteger(IL_IMAGE_WIDTH),
                          ilGetInteger(IL_IMAGE_HEIGHT), 0, ilGetInteger(IL_IMAGE_FORMAT), GL_UNSIGNED_BYTE,
                          ilGetData());
            //glTexImage2D( GL_TEXTURE_2D, 0, ilGetInteger(IL_IMAGE_BPP), ilGetInteger(IL_IMAGE_WIDTH),
            //              ilGetInteger(IL_IMAGE_HEIGHT), 0, _format, GL_UNSIGNED_BYTE,
            //              ilGetData());
        }
        else if( type == COLORTEXTURETYPE.COLOR )
        {
            _color = phong.diffuse.color;
        }
        else
        {
            throw new Exception("Unmatched type in WrappedEffect.");
        }
        writefln( "Effect [%s] is loaded!", _self.id );
    }

    void load( bool enableTexture )
    {
        
        if( enableTexture )
        {
            if( type == COLORTEXTURETYPE.TEXTURE )
                _initFrom.bind;
            else if( type == COLORTEXTURETYPE.COLOR )
                glMaterialfv( GL_FRONT, GL_DIFFUSE, _color.ptr );
                
            glMaterialfv( GL_FRONT, GL_AMBIENT,  _ambient.ptr );
            glMaterialfv( GL_FRONT, GL_SPECULAR, _specular.ptr );
            glMaterialf( GL_FRONT, GL_SHININESS, _shininess );
        }
        else
        {
            static float[4] defAmb = [ 0.2, 0.2, 0.2, 1.0 ];
            static float[4] defSpc = [ 0.0, 0.0, 0.0, 1.0 ];
            static float    defShn = 0.0;
        
            glMaterialfv( GL_FRONT, GL_AMBIENT,  defAmb.ptr );
            glMaterialfv( GL_FRONT, GL_SPECULAR, defSpc.ptr );
            glMaterialf( GL_FRONT, GL_SHININESS, defShn );
        }
    
    }

}

auto wrapEffect( Effect effect, WrappedImages* wimages )
{
    return WrappedEffect( effect, wimages );
}

struct WrappedEffects
{
    LibraryEffects _self;
    WrappedEffect[] _effects;
    alias _effects this;
    
    this( LibraryEffects libEffects, WrappedImages* wimages )
    {
        writeln( "Effects loading..." );
    
        _self = libEffects;
        
        _effects = array( map!( (a) => a.wrapEffect( wimages ) )( libEffects.effects ) );
        
        writeln( "done!" );
    }
}

auto wrapEffects( LibraryEffects libEffects, WrappedImages* wimages )
{
    return WrappedEffects( libEffects, wimages );
}

struct WrappedMaterial
{
    Material _self;
    string id;
    WrappedEffect* _instance;
    alias _instance this;
    
    this( Material material, WrappedEffects* weffects )
    {
        _self = material;
        
        id        = material.id;
        _instance = &( array( filter!( (ref a) => _self.effect.url[1..$] == a.id )( (*weffects)[] ) )[0] );
        
        writefln( "Material [%s] loaded!", _self.id );
    }
    
}

auto wrapMaterial( Material material, WrappedEffects* weffects )
{
    return WrappedMaterial( material, weffects );
}

struct WrappedMaterials
{
    LibraryMaterials _self;
    WrappedMaterial[] _materials;
    alias _materials this;
    
    this( LibraryMaterials libMaterials, WrappedEffects* weffects )
    {
        writeln( "Materials loading..." );
    
        _self = libMaterials;
        
        _materials = array( map!( (a) => a.wrapMaterial( weffects ) )( libMaterials.materials ) );
        
        writeln( "done!" );
    }
}

auto wrapMaterials( LibraryMaterials libMaterials, WrappedEffects* weffects )
{
    return WrappedMaterials( libMaterials, weffects );
}

struct WrappedVertexWeights
{
    int[2][][] _values;
    alias _values this;

    this( VertexWeights vw )
    {
        assert( vw.count == vw.vcount.length );
        
        int[][] bw;
        bw.length = 1;
        bw = reduce!( (a, b){ if(a[$-1].length < 2) a[$-1] ~= b; else a ~= [b]; return a; } )( bw, vw.v );
        
        foreach( count; vw.vcount )
        {
            int[2][] v;
            for( int i = 0; i < count; ++i )
            {
                v ~= [ bw.front[0], bw.front[1] ];
                bw.popFront;
            }
            _values ~= v;
        }
        
        assert( vw.count == _values.length );
    }
}

auto wrapVertexWeights( VertexWeights vw )
{
    return WrappedVertexWeights( vw );
}

unittest
{
    Source source;
    source.load( parseXML( q{
        <source id="Position">
          <float_array id="Position-Array" count="27"> 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 </float_array>
          <technique_common>
            <accessor source="#Position-Array" count="9" stride="3">
              <param type="float" name="X" />
              <param type="float" name="Y" />
              <param type="float" name="Z" />
            </accessor>
          </technique_common>
        </source>
    } ).root );
    
    auto wSource = source.wrapSource!float;
    assert( wSource._accessor.length == 9 );
    assert( wSource._accessor[0]._value.length == 3 );
    assert( wSource._accessor[0]._value == [0,1,2] );
    assert( wSource._accessor[8]._value.length == 3 );
    assert( wSource._accessor[8]._value == [24,25,26] );
    
    Triangles tri;
    tri.load( parseXML( q{
        <triangles count="3" material="Symbol">
          <input semantic="VERTEX" source="#Position" offset="0" />
          <p> 5 8 3 1 7 4 0 6 2 </p>
        </triangles>
    } ).root );
    
    WrappedSource!(float)[] wSources;
    wSources ~= wSource;
    
    auto wTri = tri.wrapTriangles!float( wSources );
    assert( wTri._inputs.length == 1 );
    assert( wTri._inputs[0]._init == [15,16,17, 24,25,26,  9,10,11,
                                       3, 4, 5, 21,22,23, 12,13,14,
                                       0, 1, 2, 18,19,20,  6, 7, 8 ] );
    
    Source names;
    names.load( parseXML( q{
        <source id="Joint">
          <Name_array id="Joint-Array" count="5"> Bone0 Bone1 Bone2 Bone3 Bone4 </Name_array>
          <technique_common>
            <accessor source="#Joint-Array" count="5" stride="1">
              <param name="JOINT" type="Name" />
            </accessor>
          </technique_common>
        </source>
    } ).root );
    
    auto wNames = names.wrapSource!string;
    assert( wNames._accessor.length == 5 );
    assert( wNames._accessor[0]._value == [ "Bone0" ] );
    assert( wNames._accessor[4]._value == [ "Bone4" ] );
    
    Source weights;
    weights.load( parseXML( q{
        <source id="Weight">
          <float_array id="Weight-Array" count="2"> 1.000000 0.500000 </float_array>
          <technique_common>
            <accessor source="#Weight-Array" count="2" stride="1">
              <param name="WEIGHT" type="float" />
            </accessor>
          </technique_common>
        </source>
    } ).root );
    
    auto wWeights = weights.wrapSource!float;
    assert( wWeights._accessor.length == 2 );
    assert( wWeights._accessor[0]._value == [ 1.000000 ] );
    assert( wWeights._accessor[1]._value == [ 0.500000 ] );

    VertexWeights vws;
    vws.load( parseXML( q{
        <vertex_weights count="9">
          <input semantic="JOINT" source="#Joint" offset="0" />
          <input semantic="WEIGHT" source="#Weight" offset="1" />
          <vcount>1 1 1 1 1 1 1 1 2</vcount>
          <v>0 0 1 0 2 0 3 0 4 0 0 0 1 0 2 0 3 1 4 1</v>
        </vertex_weights>
    } ).root );
    
    auto wVWs = vws.wrapVertexWeights;
    assert( wVWs._values.length == 9 );
    assert( wVWs._values[0].length == 1 );
    assert( wVWs._values[0][0] == [0,0] );
    assert( wVWs._values[8].length == 2 );
    assert( wVWs._values[8][0] == [3,1] );
    assert( wVWs._values[8][1] == [4,1] );
    
}

struct WrappedSkin
{
    struct VW
    {
        int   index;
        float weight;
    }
    struct Result
    {
        float[] matrix;
        VW[] vws;
    }
    
    Skin _self;
    
    string source;
    Result[string] result;

    this( Skin skin, WrappedGeometry* geometry )
    {
        assert( skin.source[1..$] == (*geometry).id );
        
        _self = skin;
        
        source = skin.source;

        //Name Source
        auto ns = filter!( (a) => a.type == ARRAYTYPE.NAME )( skin.sources[] ).array;
        assert( ns.length == 1 );
        
        //Name WrappedSource
        auto nws = WrappedSource!string( ns[0] );
        //Float WrappedSources
        auto fwss = map!( (a) => wrapSource!float(a) )( filter!( (b) => b.type != ARRAYTYPE.NAME )( skin.sources[] ) );
        
        //joints
        //Joint Joints Input
        auto jji = array( filter!( (a) => a.semantic == SEMANTICTYPE.JOINT )( skin.joints.inputs[] ) )[0];
        assert( jji.source[1..$] == nws.id );
        //Inverse Input
        auto ii = array( filter!( (a) => a.semantic == SEMANTICTYPE.INV_BIND_MATRIX )( skin.joints.inputs[] ) )[0];
        //Inverse WrappedSource
        auto iws = array( filter!( (a) => a.id == ii.source[1..$] )( fwss ) )[0];
        
        foreach( a, b; lockstep( nws._accessor, iws._accessor ) )
            result[ a._value[0] ] = Result( b._value, null );
        
        //vertex_weights
        //Joint Vertex Input
        auto jvi = array( filter!( (a) => a.semantic == SEMANTICTYPE.JOINT )( skin.vertex_weights.inputs[] ) )[0];
        assert( jvi.source[1..$] == nws.id );
        //Weight Input
        auto wi = array( filter!( (a) => a.semantic == SEMANTICTYPE.WEIGHT )( skin.vertex_weights.inputs[] ) )[0];
        //Weight WrappedSource
        auto wws = array( filter!( (a) => a.id == wi.source[1..$] )( fwss ) )[0];
        
        //Wrapped Vertex_Weight
        auto wvw = skin.vertex_weights.wrapVertexWeights;
        assert( wvw[].length == geometry.mesh._vertices._accessor.length );        
        
        int idx = 0;
        foreach( vw, ref param; lockstep( wvw[], geometry.mesh._vertices._accessor ) )
        {
            foreach( v; vw )
                result[ nws._accessor[v[0]]._value[0] ].vws ~= VW( idx, wws._accessor[v[1]]._value[0] );
            
            ++idx;
        }
        
        foreach( key, value; result )
            writefln( "Skin.Result[%s].vws.length = %d", key, value.vws.length );

    }
}

auto wrapSkin( Skin skin, WrappedGeometry* geometry )
{
    return WrappedSkin( skin, geometry );
}

struct WrappedController
{
    Controller _self;
    
    string id;
    WrappedSkin skin;
    
    this( Controller controller, WrappedGeometry* geometry )
    {
        _self = controller;
        
        id = controller.id;
        skin = controller.skin.wrapSkin( geometry );
    }
}

auto wrapController( Controller controller, WrappedGeometry* geometry )
{
    return WrappedController( controller, geometry );
}

struct WrappedControllers
{
    LibraryControllers _self;
    
    WrappedController[] _controllers;
    alias _controllers this;
    
    this( LibraryControllers controllers, WrappedGeometry* geometry )
    {
        _self = controllers;
        
        _controllers = array( map!( (a) => a.wrapController( geometry ) )( _self.controllers ) );
    }
}

auto wrapControllers( LibraryControllers controllers, WrappedGeometry* geometry )
{
    return WrappedControllers( controllers, geometry );
}

struct WrappedAnimation
{
    struct KeyFrame
    {
        float time;
        float[16] pose;
        string interpolation;
    }

    Animation _self;
    
    KeyFrame[] _values;
    
    string target;
    
    this( Animation animation )
    {
        _self = animation;
        
        target = _self.channels[0].target.split("/")[0];
        
        auto tws = _self.sources.filter!( (a) => a.id.split("-")[2] == "Time" ).array[0].wrapSource!(float);
        auto pws = _self.sources.filter!( (a) => a.id.split("-")[2] == "Pose" ).array[0].wrapSource!(float);
        auto iws = _self.sources.filter!( (a) => a.id.split("-")[2] == "Interpolation" ).array[0].wrapSource!(string);
        
        assert( tws._accessor.length == pws._accessor.length );
        assert( pws._accessor.length == iws._accessor.length );
        assert( iws._accessor.length == tws._accessor.length );
        
        foreach( time, pose, interpolation; lockstep( tws._accessor, pws._accessor, iws._accessor ) )
        {
            KeyFrame keyframe;
            keyframe.time = time._value[0];
            keyframe.pose = transpose( pose._value );
            keyframe.interpolation = interpolation._value[0];

            _values ~= keyframe;
        }
        
        writefln( "Animation [%s] loaded!", _self.id );
    }

}

auto wrapAnimation( Animation animation )
{
    return WrappedAnimation( animation );
}

struct WrappedAnimations
{
    LibraryAnimations _self;
    
    WrappedAnimation[] animations;
    
    this( LibraryAnimations libAnimations )
    {
        writeln( "Animations loading..." );
        
        _self = libAnimations;
        
        animations = array( map!( (a) => a.wrapAnimation() )( _self.animations ) );
        
        writeln( "done!" );
    }

}

auto wrapAnimations( LibraryAnimations libAnimations )
{
    return WrappedAnimations( libAnimations );
}

enum Step { NEXT, PREV };
/+
struct WrappedBone
{
    WrappedBone*  parent;
    Node          _self; 
    WrappedBone[] children;
    
    string id;
    float[16] matrix = [ 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0 ];
    float[16] pose = [ 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0 ];
    
    //アニメーション計算用
    WrappedAnimation.KeyFrame[] keyframes;
    bool hasAnimation = false;
    uint startIndex = -1;
    uint endIndex = -1;
    
    //IK計算用
    bool isIK = false;
    WrappedBone* IKTarget;
    int IKChain;
    int IKIterations;
    float IKWeight;

    //さかのぼれる限りの親と自分の poseを乗算した結果
    //これを持っておけば子の pose計算時に毎回親をさかのぼる必要が無くなり
    //(親の pp x 自分の pose だけで済む) 計算量が減らせる。
    float[16] pp = [ 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0 ];
    
    //constructor内で childに親情報として &thisを渡そうと思ったが
    //アドレスが何処かで置き換えられるらしく正常な参照先を渡せないので
    //その処理か下記の connectKeyFramesで合わせて行う。
    this( Node node )
    {
        _self = node;
        
        id = node.id;
        
        assert( node.matrixes.length == 1 );
        pose = transpose( node.matrixes[0] ); 
        
        writefln( "Bone [%s] loaded!", _self.id );
        
        foreach( child; node.nodes )
            children ~= child.wrapBone;
    }

    //選択されたアニメーションをモデルに読み込む
    void connectKeyFrames( WrappedAnimations* animations )
    {
        foreach( ref animation; animations.animations )
        {
            if( animation.target != _self.id ) continue;
            keyframes = animation._values;
            hasAnimation = true;
            assert( keyframes.length >= 2 );
            startIndex = 0;
            endIndex = 1;
            
            writefln( "Bone [%s] keyframes connected!", _self.id );
            break;
        }
        
        foreach( ref child; children )
        {
            child.parent = &this;
            child.connectKeyFrames( animations );
        }
    }
    
    void connectVertexWeights( WrappedSource!(float)* source, WrappedController* controller )
    {
        if( _self.id in controller.skin.result )
        {
            auto result = controller.skin.result[ _self.id ];
            matrix = transpose( result.matrix );
            
            foreach( vw; result.vws )
                source._accessor[ vw.index ]._bwRefs ~= WrappedSource!float.BW( &this, vw.weight );
            
            writefln( "Bone [%s] vertex weights connected!", _self.id );
        }
        else
        {
            writefln( "%s's skin not found.", _self.id );
        }
        
        foreach( ref child; children )
            child.connectVertexWeights( source, controller );
    }

    void calcPose( Step step, ref const float time )
    {
        
        if( hasAnimation )
        {

            final switch( step )
            {
                case Step.NEXT :
                {
                    while( time > keyframes[ endIndex ].time )
                    {
                        if( endIndex < keyframes.length -1 )
                        {
                            startIndex++;
                            endIndex++;
                        }
                        else break;
                    }
                } break;

                case Step.PREV :
                {
                    while( keyframes[ startIndex ].time > time )
                    {
                        if( startIndex > 0 )
                        {
                            startIndex--;
                            endIndex--;
                        }
                        else break;
                    }
                } break;
            }

            auto s = &(keyframes[startIndex]);
            auto e = &(keyframes[endIndex]);
            
            if( s.pose != e.pose )
            {
                float t = time - s.time;
                t /= e.time - s.time;
                
                float[3] st = s.pose[12..15];
                float[3] et = e.pose[12..15];
                float[3] trans = Lerp( st, et, t );
                //float[3] trans = ( st == et ) ? st : Lerp( st, et, t );
                
                Quaternion sq = s.pose.toQuaternion;
                Quaternion eq = e.pose.toQuaternion;
                
                if( eq.x < 0.0 ) {
                    if( sq.x == 1 ) sq.x = -1;
                } else {
                    if( sq.x == -1 ) sq.x = 1;
                }
                if( eq.y < 0.0 ) {
                    if( sq.y == 1 ) sq.y = -1;
                } else {
                    if( sq.y == -1 ) sq.y = 1;
                }
                if( eq.z < 0.0 ) {
                    if( sq.z == 1 ) sq.z = -1;
                } else {
                    if( sq.z == -1 ) sq.z = 1;
                }
                
                float[16] mat = Slerp( sq, eq, t ).toMatrix();
                //float[16] mat = ( sq == eq ) ? s.pose : Slerp( sq, eq, t ).toMatrix();
                
                mat[12..15] = trans;
                pose = mat;
/+
                if( ( id == "左足IK" ) || ( id == "右足IK" ) )
                {
                writeln( "----- id : ", id, " -----" );
                writeln( "t : ", t );
                writeln( "s.pose : ", s.pose );
                writeln( "e.pose : ", e.pose );
                writeln( "sq : ", sq );
                writeln( "eq : ", eq );
                writeln( "slerp : ", Slerp( sq, eq, t ) );
                writeln( "pose : ", pose );
                writeln( "" );
                }
+/
                
            }
            else
                pose = s.pose;
                
        }
        
        if( parent == null )
            pp = pose;
        else
            pp = multMatrix( pose, parent.pp );
        
        //foreach( ref child; taskPool.parallel( children ) )
        foreach( ref child; children )
            child.calcPose( step, time );
            
    }

    void calcIK()
    {
        float[3] getVertex( WrappedBone* b )
        {
            float[4] cv = b.matrix[12..15] ~ 1.0 ;
            if( cv[0] != 0.0 ) cv[0] *= -1;
            if( cv[1] != 0.0 ) cv[1] *= -1;
            if( cv[2] != 0.0 ) cv[2] *= -1;
            
            multr( cv, b.matrix );
            multr( cv, b.pose );
            
            auto p = b.parent;
            while( p != null )
            {
                multr( cv, p.pose );
                p = p.parent;
            }

            return [ cv[0], cv[1], cv[2] ];
        }

        if( isIK )
        //if( ( isIK ) && ( (id == "右足ＩＫ") || (id == "左足ＩＫ") ) )
        //if( ( isIK ) && (id == "右足ＩＫ") )
        //if( ( isIK ) && ( id == "ﾈｸﾀｲＩＫ" ) )
        {
            //writeln( "" );
            //writeln( "---------- IK.id : ", this.id, " ----------" );
            for( int i = 0; i < IKIterations; ++i )
            {
                auto effector = &(IKTarget.children[0]);
                auto joint = effector.parent;
                
                for( int j = 0; j < IKChain; ++j )
                {
                    float[3] before = getVertex( effector );
                    before[] -= getVertex( joint )[];
                    normalize( before );
                    
                    float[3] after = getVertex( &this );
                    after[] -= getVertex( joint )[];
                    normalize( after );
                    
                    float[3] axis = cross( before, after );
                    if( axis != [ 0.0, 0.0, 0.0 ] )
                    {
                        normalize( axis );
                        float radian = acos( clamp( dot( before, after ), -1.0, 1.0 ) );
                
                        //if( radian > 1.0e-5f )
                        {
                            Quaternion q1 = makeQuaternion( axis, radian );
                            Quaternion q2 = joint.pose.toQuaternion();
                            
                            if( (joint.id == "左ひざ") || (joint.id == "右ひざ") )
                            {
/+        
                                float[3] max = getVertex( joint );
                                max[] -= getVertex( joint.parent )[];
                                normalize( max );
                                
                                float[3] maxAxis = cross( before, max );
                                normalize( maxAxis );
                                float maxRadian = acos( clamp( dot( before, max ), -1.0, 1.0 ) );
                                
                                //assert( axis == maxAxis );
                                writeln( "axis : ", axis );
                                writeln( "max  : ", maxAxis );
                                writeln( "radian : ", radian );
                                writeln( "max    : ", maxRadian );
                            
                                assert( axis[0] != 0.0 );
                                if( axis[0] > 0.0 )
                                {
                                    if( radian < maxRadian )
                                        radian = maxRadian;
                                }
                                else
                                {
                                    if( radian > maxRadian )
                                        radian = maxRadian;
                                }
                            
                                q1 = makeQuaternion( axis, radian );
+/                                
                                float[3] euler = q1.toEuler();
                                float zero = 0.0;
                                q1 = makeQuaternion( zero, zero, euler[2] );
                                
                                //膝回転制限
                                //if( q1.x < 0.0 ) q1.x = 0.0; 
                                //if( q.x > 0.9 ) q.x = 0.9; 
                                //q.normalize();
                            }
                            
                            float[16] qmat = multQuaternion( q1, q2 ).toMatrix();
                            qmat[12..15] = joint.pose[12..15];
        
                            joint.pose = qmat;

                            writeln( joint.id );
                            writeln(  "ikpos         : ", getVertex( &this ) );
                            writefln( "effector[%s]  : %s", effector.id.toMBSz.to!string, getVertex( effector ) );
                            writefln( "joint[%s]     : %s", joint.id, getVertex( joint ) );
                            writeln(  "before vector : ", before );
                            writeln(  "after vector  : ", after );
                            writeln(  "axis          : ", axis );
                            writeln(  "radian        : ", radian );
                            //writeln(  "angle         : ", radian * 180 / PI );
                            //writeln( "after joint.pose", joint.pose );


                        }                        

                    }
                    joint = joint.parent;

                }//for IKChain
            }//for IKIterations
        }//if( isIK )

        foreach( ref child; children )
            //if( child.isIK )
                child.calcIK();
    }//calcIK

}
+/

struct WrappedBone
{
    WrappedBone*  parent;
    Node          _self; 
    WrappedBone[] children;
    
    string id;
    Matrix4x4 matrix = identity4x4;
    Matrix4x4 pose   = identity4x4;
    
    //アニメーション計算用
    WrappedAnimation.KeyFrame[] keyframes;
    bool hasAnimation = false;
    uint startIndex = -1;
    uint endIndex = -1;
    
    //IK計算用
    bool isIK = false;
    WrappedBone* IKTarget;
    int IKChain;
    int IKIterations;
    float IKWeight;

    //さかのぼれる限りの親と自分の poseを乗算した結果
    //これを持っておけば子の pose計算時に毎回親をさかのぼる必要が無くなり
    //(親の pp x 自分の pose だけで済む) 計算量が減らせる。
    Matrix4x4 pp = identity4x4;
    
    //constructor内で childに親情報として &thisを渡そうと思ったが
    //アドレスが何処かで置き換えられるらしく正常な参照先を渡せないので
    //その処理か下記の connectKeyFramesで合わせて行う。
    this( Node node )
    {
        _self = node;
        
        id = node.id;
        
        assert( node.matrixes.length == 1 );
        pose = transpose( node.matrixes[0] ); 
        
        writefln( "Bone [%s] loaded!", _self.id );
        
        foreach( child; node.nodes )
            children ~= child.wrapBone;
    }

    //選択されたアニメーションをモデルに読み込む
    void connectKeyFrames( WrappedAnimations* animations )
    {
        foreach( ref animation; animations.animations )
        {
            if( animation.target != _self.id ) continue;
            keyframes = animation._values;
            hasAnimation = true;
            assert( keyframes.length >= 2 );
            startIndex = 0;
            endIndex = 1;
            
            writefln( "Bone [%s] keyframes connected!", _self.id );
            break;
        }
        
        foreach( ref child; children )
        {
            child.parent = &this;
            child.connectKeyFrames( animations );
        }
    }
    
    void connectVertexWeights( WrappedSource!(float)* source, WrappedController* controller )
    {
        if( _self.id in controller.skin.result )
        {
            auto result = controller.skin.result[ _self.id ];
            matrix = transpose( result.matrix );
            
            foreach( vw; result.vws )
                source._accessor[ vw.index ]._bwRefs ~= WrappedSource!float.BW( &this, vw.weight );
            
            writefln( "Bone [%s] vertex weights connected!", _self.id );
        }
        else
        {
            writefln( "%s's skin not found.", _self.id );
        }
        
        foreach( ref child; children )
            child.connectVertexWeights( source, controller );
    }

    void calcPose( Step step, ref const float time )
    {
        
        if( hasAnimation )
        {

            final switch( step )
            {
                case Step.NEXT :
                {
                    while( time > keyframes[ endIndex ].time )
                    {
                        if( endIndex < keyframes.length -1 )
                        {
                            startIndex++;
                            endIndex++;
                        }
                        else break;
                    }
                } break;

                case Step.PREV :
                {
                    while( keyframes[ startIndex ].time > time )
                    {
                        if( startIndex > 0 )
                        {
                            startIndex--;
                            endIndex--;
                        }
                        else break;
                    }
                } break;
            }

            auto s = &(keyframes[startIndex]);
            auto e = &(keyframes[endIndex]);
            
            if( s.pose != e.pose )
            {
                float t = time - s.time;
                t /= e.time - s.time;
                
                Quaternion sq = Matrix4x4( s.pose ).getTransform.toQuaternion;
                Quaternion eq = Matrix4x4( e.pose ).getTransform.toQuaternion;
                
                if( eq.x < 0.0 ) {
                    if( sq.x == 1 ) sq.x = -1;
                } else {
                    if( sq.x == -1 ) sq.x = 1;
                }
                if( eq.y < 0.0 ) {
                    if( sq.y == 1 ) sq.y = -1;
                } else {
                    if( sq.y == -1 ) sq.y = 1;
                }
                if( eq.z < 0.0 ) {
                    if( sq.z == 1 ) sq.z = -1;
                } else {
                    if( sq.z == -1 ) sq.z = 1;
                }
                
                Vector3 sv = Matrix4x4( s.pose ).getOrigin;
                Vector3 ev = Matrix4x4( e.pose ).getOrigin;
                
                pose.setTransform( Slerp( sq, eq, t ).toMatrix3x3 );
                pose.setOrigin( Lerp( sv, ev, t ) );
                
/+                
                if( ( id == "左足IK" ) || ( id == "右足IK" ) )
                {
                    writeln( "----- id : ", id, " -----" );
                    writeln( "t : ", t );
                    writeln( "s.pose : ", s.pose );
                    writeln( "e.pose : ", e.pose );
                    writeln( "sq : ", sq );
                    writeln( "eq : ", eq );
                    writeln( "slerp : ", Slerp( sq, eq, t ) );
                    writeln( "pose : ", pose );
                    writeln( "" );
                }
+/
                
            }
            else
                pose = s.pose;
                
        }
        
        if( parent == null )
            pp = pose;
        else
            pp = multMatrix( pose, parent.pp );
        
        //foreach( ref child; taskPool.parallel( children ) )
        foreach( ref child; children )
            child.calcPose( step, time );
            
    }

    void calcIK()
    {
        float[3] getVertex( WrappedBone* b )
        {
            float[4] cv = b.matrix[12..15] ~ 1.0 ;
            if( cv[0] != 0.0 ) cv[0] *= -1;
            if( cv[1] != 0.0 ) cv[1] *= -1;
            if( cv[2] != 0.0 ) cv[2] *= -1;
            
            multr( cv, b.matrix );
            multr( cv, b.pose );
            
            auto p = b.parent;
            while( p != null )
            {
                multr( cv, p.pose );
                p = p.parent;
            }

            return [ cv[0], cv[1], cv[2] ];
        }

        if( isIK )
        {
            for( int i = 0; i < IKIterations; ++i )
            {
                auto effector = &(IKTarget.children[0]);
                auto joint = effector.parent;
                
                for( int j = 0; j < IKChain; ++j )
                {
                    Vector3 before = Vector3( getVertex( effector ) );
                    before[] -= getVertex( joint )[];
                    
                    Vector3 after = Vector3( getVertex( &this ) );
                    after[] -= getVertex( joint )[];
                    
                    Matrix3x3 inv = joint.pose.getTransform;
                    //inv = inv.inverse;
                    
                    before = before.multMatrix3x3( inv );
                    after  = after.multMatrix3x3( inv );
                    
                    normalize( before );
                    normalize( after );
                    
                    Vector3 axis = cross( before, after );
                    normalize( axis );
                    
                    float radian = acos( clamp( dot( before, after ), -1.0, 1.0 ) );
                    
                    if( radian > IKWeight )
                        radian = IKWeight;
                    else if( radian < -IKWeight )
                        radian = -IKWeight;
                        
                    Quaternion q1 = makeQuaternion( axis, radian );
                    
                    if( (joint.id == "左ひざ") || (joint.id == "右ひざ") )
                    {
                        if( i == 0 )
                        {
                            if( radian < 0.0f )
                                radian = -radian;
                            axis = [ 1.0, 0.0, 0.0 ];
                            q1 = makeQuaternion( axis, radian );
                        }
                        else
                        {
                            Vector3 euler1 = q1.toEuler;
                            Vector3 euler2 = joint.pose.getTransform.toQuaternion.toEuler;
                            
                            if( euler1[2] + euler2[2] > PI )
                                euler1[2] = PI - euler2[2];
                                
                            if( euler1[2] + euler2[2] < 0.002f )
                                euler1[2] = 0.002f - euler2[2];
                                
                            if( euler1[2] > IKWeight )
                                euler1[2] = IKWeight;
                            else if( euler1[2] < -IKWeight )
                                euler1[2] = -IKWeight;
                                                
                            q1 = makeQuaternion( 0.0, 0.0, euler1[2] );
                        
                        }
                    }
                    
                    auto qj = joint.pose.getTransform.toQuaternion;
                    
                    joint.pose.setTransform( multQuaternion( q1, qj ).toMatrix3x3 );

                    joint = joint.parent;

                }//for IKChain
            }//for IKIterations
        }//if( isIK )

        foreach( ref child; children )
            child.calcIK();
    }//calcIK
    
/+    
    void calcIK()
    {
        float[3] getVertex( WrappedBone* b )
        {
            float[4] cv = b.matrix[12..15] ~ 1.0 ;
            if( cv[0] != 0.0 ) cv[0] *= -1;
            if( cv[1] != 0.0 ) cv[1] *= -1;
            if( cv[2] != 0.0 ) cv[2] *= -1;
            
            multr( cv, b.matrix );
            multr( cv, b.pose );
            
            auto p = b.parent;
            while( p != null )
            {
                multr( cv, p.pose );
                p = p.parent;
            }

            return [ cv[0], cv[1], cv[2] ];
        }

        if( isIK )
        //if( ( isIK ) && ( (id == "右足ＩＫ") || (id == "左足ＩＫ") ) )
        //if( ( isIK ) && (id == "右足ＩＫ") )
        //if( ( isIK ) && ( id == "ﾈｸﾀｲＩＫ" ) )
        {
            //writeln( "" );
            //writeln( "---------- IK.id : ", this.id, " ----------" );
            for( int i = 0; i < IKIterations; ++i )
            {
                auto effector = &(IKTarget.children[0]);
                auto joint = effector.parent;
                
                for( int j = 0; j < IKChain; ++j )
                {
                    float[3] before = getVertex( effector );
                    before[] -= getVertex( joint )[];
                    normalize( before );
                    
                    float[3] after = getVertex( &this );
                    after[] -= getVertex( joint )[];
                    normalize( after );
                    
                    float[3] axis = cross( before, after );
                    if( axis != [ 0.0, 0.0, 0.0 ] )
                    {
                        normalize( axis );
                        float radian = acos( clamp( dot( before, after ), -1.0, 1.0 ) );
                
                        //if( radian > 1.0e-5f )
                        {
                            Quaternion q1 = makeQuaternion( axis, radian );
                            Quaternion q2 = joint.pose.toQuaternion();
                            
                            if( (joint.id == "左ひざ") || (joint.id == "右ひざ") )
                            {
/+        
                                float[3] max = getVertex( joint );
                                max[] -= getVertex( joint.parent )[];
                                normalize( max );
                                
                                float[3] maxAxis = cross( before, max );
                                normalize( maxAxis );
                                float maxRadian = acos( clamp( dot( before, max ), -1.0, 1.0 ) );
                                
                                //assert( axis == maxAxis );
                                writeln( "axis : ", axis );
                                writeln( "max  : ", maxAxis );
                                writeln( "radian : ", radian );
                                writeln( "max    : ", maxRadian );
                            
                                assert( axis[0] != 0.0 );
                                if( axis[0] > 0.0 )
                                {
                                    if( radian < maxRadian )
                                        radian = maxRadian;
                                }
                                else
                                {
                                    if( radian > maxRadian )
                                        radian = maxRadian;
                                }
                            
                                q1 = makeQuaternion( axis, radian );
+/                                
                                float[3] euler = q1.toEuler();
                                float zero = 0.0;
                                q1 = makeQuaternion( zero, zero, euler[2] );
                                
                                //膝回転制限
                                //if( q1.x < 0.0 ) q1.x = 0.0; 
                                //if( q.x > 0.9 ) q.x = 0.9; 
                                //q.normalize();
                            }
                            
                            float[16] qmat = multQuaternion( q1, q2 ).toMatrix();
                            qmat[12..15] = joint.pose[12..15];
        
                            joint.pose = qmat;

                            writeln( joint.id );
                            writeln(  "ikpos         : ", getVertex( &this ) );
                            writefln( "effector[%s]  : %s", effector.id.toMBSz.to!string, getVertex( effector ) );
                            writefln( "joint[%s]     : %s", joint.id, getVertex( joint ) );
                            writeln(  "before vector : ", before );
                            writeln(  "after vector  : ", after );
                            writeln(  "axis          : ", axis );
                            writeln(  "radian        : ", radian );
                            //writeln(  "angle         : ", radian * 180 / PI );
                            //writeln( "after joint.pose", joint.pose );


                        }                        

                    }
                    joint = joint.parent;

                }//for IKChain
            }//for IKIterations
        }//if( isIK )

        foreach( ref child; children )
            //if( child.isIK )
                child.calcIK();
    }//calcIK
+/

}

auto wrapBone( Node node )
{
    return WrappedBone( node );
}

struct WrappedNode
{
    struct Instance
    {
        WrappedTriangles!(float)* triangles;
        WrappedMaterial*          material;
        
        void load( bool enableTexture )
        {
            material.load( enableTexture );
            triangles.load( enableTexture );
        }
    }

    Node _self;

    string id;
    Translate[] translates;
    Rotate[]    rotates;
    Scale[]     scales;

    Instance[] instances;

    this( Node node, WrappedGeometry* geometry, WrappedMaterials* materials )
    {
        writeln( "Nodes loading..." );
        
        _self = node;
        
        translates = _self.translates;
        rotates    = _self.rotates;
        scales     = _self.scales;

        foreach( ins; node.instanceControllers[0].bindMaterial.common.instanceMaterials )
        {
            instances ~= Instance( &(array( filter!( (ref a) => a._self.material == ins.symbol )( (*geometry).mesh[]) )[0] ),
                                   &(array( filter!( (ref b) => b.id == ins.target[1..$] )( (*materials)[]) )[0] ) );
            writefln( "Instance [%s] loaded!", ins.symbol );
        }
        
        writeln( "done!" );
    }

    void load( bool enableTexture )
    {
        foreach( ref translate; translates )
            glTranslatef( translate[0], translate[1], translate[2] );
            
        foreach( ref rotate; rotates )
            glRotatef( rotate[3], rotate[0], rotate[1], rotate[2] );
            
        foreach( ref scale; scales )
            glScalef( scale[0], scale[1], scale[2] );
            
        foreach( ref instance; instances )
            instance.load( enableTexture );
    }
}

auto wrapNode( Node node, WrappedGeometry* geometry, WrappedMaterials* materials )
{
    return WrappedNode( node, geometry, materials );
}

struct IKConfig
{
    XMLElement self;

    this( XMLElement xml )
    {
        self = xml;
    }
    
    void set( WrappedBone* bone )
    {
        WrappedBone* findBone( WrappedBone* _bone, string name )
        {
            if( name == _bone.id )
                return _bone;
            
            foreach( ref child; _bone.children )
            {
                WrappedBone* temp = findBone( &child, name );
                if( temp != null ) return temp;
            }
            
            return null;
        }
    
        foreach( ik; self.elems )
        {
            assert( ik.attrs[1].name == "target" );
            auto ikEffect = findBone( bone, ik.attrs[1].value );
            ikEffect.isIK = true;
            
            assert( ik.attrs[0].name == "name" );
            ikEffect.IKTarget = findBone( bone, ik.attrs[0].value );
            assert( ik.attrs[2].name == "chain" );
            ikEffect.IKChain = ik.attrs[2].value.to!int;
            assert( ik.attrs[3].name == "iterations" );
            ikEffect.IKIterations = ik.attrs[3].value.to!int;
            assert( ik.attrs[4].name == "weight" );
            ikEffect.IKWeight = ik.attrs[4].value.to!float * PI;
        }
    }
}

struct ColladaModel
{
    Collada _self;
    string path;

    WrappedImages images;
    WrappedEffects effects;
    WrappedMaterials materials;
    WrappedGeometries geometries;
    WrappedControllers controllers;
    WrappedAnimations[] animations;

    WrappedBone bone;
    WrappedNode node;

    bool enableTexture = true;
    bool enableBone    = true;

    float startTime = 0.0;
    float currentTime = 0.0;
    bool isMoving = false;

    this( Collada collada, string modelDir )
    {
        _self = collada;
        path = modelDir;
        
        images = collada.libImages.wrapImages( path );
        effects = collada.libEffects.wrapEffects( &images );
        materials = collada.libMaterials.wrapMaterials( &effects );
        geometries = collada.libGeometries.wrapGeometries;
        controllers = collada.libControllers.wrapControllers( &(geometries[0]) );
        animations ~= collada.libAnimations.wrapAnimations;
        
        bone = collada.libVisualScenes.visualScenes[0].nodes[0].wrapBone();
        bone.connectVertexWeights( geometries[0].mesh._vertices, &(controllers[0]) );
        
        node = collada.libVisualScenes.visualScenes[0].nodes[1].wrapNode( &(geometries[0]), &materials );

    }

    ~this()
    {
        foreach( image; images[] )
            image.release;
    }

    void selectAnimation( uint number )
    {
        writeln( "selected Animation" );
        assert( number < animations.length );
        
        bone.connectKeyFrames( &( animations[number] ) );
        
        auto ikConfig = IKConfig( parseXML( import( "AppearanceMikuA_ik.config" ) ).root );
        //auto ikConfig = IKConfig( parseXML( import( "Lat_White_ne_ik.config" ) ).root );
        //auto ikConfig = IKConfig( parseXML( import( "Lat_Normal_ik.config" ) ).root );
        //auto ikConfig = IKConfig( parseXML( import( "Ver2_ik.config" ) ).root );
        ikConfig.set( &bone );
        
        isMoving = true;
        startTime = glfwGetTime();
        currentTime = 0.0;
    }

    float __interval = 0.0;
    void suspend()
    {
        if( !isMoving ) return;

        isMoving = false;
        __interval = glfwGetTime();
    }
    
    void resume()
    {
        if( isMoving ) return;
        if( __interval == 0.0 ) return;

        __interval = glfwGetTime - __interval;

        isMoving = true;
        startTime += __interval;
        __interval = 0.0;
    }
    
    void moveStep( Step step, float time )
    {
        if( isMoving ) return;

        final switch( step )
        {
            case Step.NEXT :
            {
                currentTime += time;
                bone.calcPose( Step.NEXT, currentTime );
                bone.calcIK();
            } break;

            case Step.PREV : 
            { 
                currentTime -= time;
                bone.calcPose( Step.PREV, currentTime );
                bone.calcIK();
            } break;
        }

        geometries[0].mesh._vertices.calc();
    }

    void move()
    {
        if( !isMoving ) return;
        
        currentTime = glfwGetTime - startTime;
        bone.calcPose( Step.NEXT, currentTime );
        bone.calcIK();
        geometries[0].mesh._vertices.calc();
        
    }

    void draw()
    {
        
        if( enableTexture )
        {
            glEnable( GL_LINE_SMOOTH );
            glEnable( GL_TEXTURE_2D );
            glEnable( GL_BLEND );
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
            glPushMatrix();
                node.load( true );
            glPopMatrix();
            
            glDisable( GL_BLEND );
            glDisable( GL_TEXTURE_2D );
            glDisable( GL_LINE_SMOOTH );
        }
        else
        {            
            glPushMatrix();
                node.load( false );
            glPopMatrix();
        }

        if( enableBone ) drawBone();
        
    }
    
    void drawBone()
    {
        void makeBone( WrappedBone current, float[4] pv, int depth = 0 )
        {
            
            float[4] cv;
            cv[0] = current.matrix[12] == 0.0 ? 0.0 : -current.matrix[12];
            cv[1] = current.matrix[13] == 0.0 ? 0.0 : -current.matrix[13];
            cv[2] = current.matrix[14] == 0.0 ? 0.0 : -current.matrix[14];
            cv[3] = 1.0;
            
            multr( cv, current.matrix );
            //multr( cv, current.pp );
            multr( cv, current.pose );
            
            auto p = current.parent;
            while( p != null )
            {
                multr( cv, p.pose );
                p = p.parent;
            }
            
            if( ( current.id == "右足ＩＫ" ) || ( current.id == "右つま先ＩＫ") )
                glColor3f( 0, 1, 0 );

            if( ( current.id == "右足首先" ) || ( current.id == "右足首" ) ||
                ( current.id == "右ひざ" ) || ( current.id == "右足" ) )
                glColor3f( 0, 1, 1 );

            if( ( current.id == "左足ＩＫ" ) || ( current.id == "左つま先ＩＫ") )
                glColor3f( 1, 0, 0 );
            
            if( ( current.id == "左足首先" ) || ( current.id == "左足首" ) ||
                ( current.id == "左ひざ" ) || ( current.id == "左足" ) )
                glColor3f( 1, 0, 1 );
            
            glBegin( GL_POINTS );
            glVertex3f( cv[0], cv[1], cv[2] );
            glEnd();
            
            glBegin( GL_LINES );
            glVertex3f( pv[0], pv[1], pv[2] );
            glVertex3f( cv[0], cv[1], cv[2] );
            glEnd();

            glColor3f( 0.8, 0.8, 0.8 );
            
            if( ( current.id == "左ひざ" ) || ( current.id == "左足" ) || 
                ( current.id == "右ひざ" ) || ( current.id == "右足" ) )
            {
                float[4] cv_;
                cv_[0] = current.matrix[12] == 0.0 ? 0.0 : -current.matrix[12];
                cv_[1] = current.matrix[13] == 0.0 ? 0.0 : -current.matrix[13];
                cv_[2] = current.matrix[14] == 0.0 ? 0.0 : -current.matrix[14];
                cv_[3] = 1.0;
                
                float[4] cvx = cv_.dup;
                cvx[0] += 1.0;
                float[4] cvy = cv_.dup;
                cvy[1] += 1.0;
                float[4] cvz = cv_.dup;
                cvz[2] += 1.0;
                
                multr( cv_, current.matrix );
                multr( cvx, current.matrix );
                multr( cvy, current.matrix );
                multr( cvz, current.matrix );
                
                multr( cv_, current.pose );
                multr( cvx, current.pose );
                multr( cvy, current.pose );
                multr( cvz, current.pose );
                
                auto _p = current.parent;
                while( _p != null )
                {
                    multr( cv_, _p.pose );
                    multr( cvx, _p.pose );
                    multr( cvy, _p.pose );
                    multr( cvz, _p.pose );
                    _p = _p.parent;
                }
            
                glBegin( GL_POINTS );
                glColor3f( 1, 0, 0 );
                glVertex3f( cvx[0], cvx[1], cvx[2] );
                glColor3f( 0, 1, 0 );
                glVertex3f( cvy[0], cvy[1], cvy[2] );
                glColor3f( 0, 0, 1 );
                glVertex3f( cvz[0], cvz[1], cvz[2] );
                glEnd();
                
                glBegin( GL_LINES );
                glColor3f( 1, 0, 0 );
                glVertex3f( cv_[0], cv_[1], cv_[2] );
                glVertex3f( cvx[0], cvx[1], cvx[2] );
                glColor3f( 0, 1, 0 );
                glVertex3f( cv_[0], cv_[1], cv_[2] );
                glVertex3f( cvy[0], cvy[1], cvy[2] );
                glColor3f( 0, 0, 1 );
                glVertex3f( cv_[0], cv_[1], cv_[2] );
                glVertex3f( cvz[0], cvz[1], cvz[2] );
                glEnd();    
                
                glColor3f( 0.8, 0.8, 0.8 );
            }

            if( current.children.empty ) return;

            foreach( child; current.children )
                makeBone( child, cv, depth+1 );
        }
        
        glDisable(GL_DEPTH_TEST);
        
        glPushMatrix();
            glEnable(GL_LINE_SMOOTH);
            glLineWidth(2);
            glPointSize(8);
            glColor3f( 0.8, 0.8, 0.8 );        
            makeBone( bone, [0.0f, 0.0f, 0.0f, 1.0] );
            glColor3f( 1, 1, 1 );        
            glPointSize(1);
            glLineWidth(1);
            glDisable(GL_LINE_SMOOTH);
        glPopMatrix();
        
        glEnable(GL_DEPTH_TEST);
    }
}
