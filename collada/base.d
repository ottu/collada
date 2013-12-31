module collada.base;

import std.algorithm;
import std.conv;

version( unittest )
{
	import std.stdio;
}

import adjustxml;

struct SIDValue
{
	string sid;
	float value = float.nan;
	alias value this;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.texts.length == 1 );
	}
	out
	{
		assert( this.isValid );
	}
	body
	{
		if( xml.attrs.length == 1 )
		{
			assert( xml.attrs[0].name == "sid" );
			this.sid = xml.attrs[0].value;
		}
		
		this.value = to!float( xml.texts[0] );
	}
	
	bool isValid() { return this.value != float.nan; }
}

struct FloatCount(int count)
{
	float[count] value;
	alias value this;
	
	void load( XMLElement xml )
	in
	{
		//assert( xml.tag == "color" );
		assert( xml.texts.length == count );
	}
	out
	{
		assert( this.isValid );
	}
	body
	{
		foreach( i, text; xml.texts )
			value[i] = to!float( text );
	}
		
	bool isValid() { return reduce!"a && (b != float.nan)"( true, value[] ); }
}

alias FloatCount!(1) Float1;
alias FloatCount!(2) Float2;
alias FloatCount!(3) Float3;
alias FloatCount!(4) Float4;
alias FloatCount!(16) Float16;

enum COLORTEXTURETYPE : byte
{
	COLOR,
	PARAM,
	TEXTURE,
	NONE
}

struct Texture
{
	string texture;
	string texcoord;
	//[]extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "texture" );
		assert( xml.attrs.length == 2 );
		assert( xml.elems.length == 0 );
	}
	out
	{
		assert( texture != "" );
		assert( texcoord != "" );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "texture"  : { texture  = attr.value; } break;
				case "texcoord" : { texcoord = attr.value; } break;
				default : { throw new Exception("Texture(base) attribure switch faild." ); } break;
			}
		}
	}
}

struct CommonColorOrTextureType
{
	union
	{
		Float4 color;
		Float4 param;
		Texture texture;
	}
	
	COLORTEXTURETYPE type = COLORTEXTURETYPE.NONE;
	
	void load( XMLElement xml )
	in
	{
		assert( [ "ambient", "diffuse", "emission", 
		          "reflective", "specular", "transparent" ].find( xml.tag ) != [] );
		assert( xml.elems.length == 1 );
	}
	out
	{
		assert( type != COLORTEXTURETYPE.NONE );
	}
	body
	{
		switch( xml.elems[0].tag )
		{
			case "color" :
			{ 
				type = COLORTEXTURETYPE.COLOR;
				color.load( xml.elems[0] );
			}break;
			
			case "param" : 
			{
				type = COLORTEXTURETYPE.PARAM;
				param.load( xml.elems[0] );
			} break;
			
			case "texture" :
			{
				type = COLORTEXTURETYPE.TEXTURE;
				texture.load( xml.elems[0] );
			} break;
			
			default : { throw new Exception("CommonColorOrTextureType element switch faild."); } break;
		}
	}
		
}

enum FLOATPARAMTYPE : byte
{
	FLOAT,
	PARAM,
	NONE
}

struct CommonFloatOrParamType
{

	union
	{
		Float1 float_;
		Float1 param;
	}
	
	FLOATPARAMTYPE type = FLOATPARAMTYPE.NONE;
	
	void load( XMLElement xml )
	in
	{
		//assert( [ "shininess", "reflectivity", "transparency", "index_of_refraction" ].find!( xml.tag ) != [] );
		assert( xml.elems.length == 1 );
	}
	out
	{
		assert( type != FLOATPARAMTYPE.NONE );
	}
	body
	{
		switch( xml.elems[0].tag )
		{
			case "float" :
			{
				type = FLOATPARAMTYPE.FLOAT;
				float_.load( xml.elems[0] );
			} break;
			
			case "param" :
			{ 
				type = FLOATPARAMTYPE.PARAM;
				param.load( xml.elems[0] );
			} break;
			
			default : {} break;
		}
	}		
}

struct Constant
{

	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "constant" );
	}
	out
	{
	
	}
	body
	{
	
	}

}

struct Lambert
{

	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "lambert" );
	}
	out
	{
	
	}
	body
	{
	
	}
}

struct Phong
{

	CommonColorOrTextureType emission;
	CommonColorOrTextureType ambient;
	CommonColorOrTextureType diffuse;
	CommonColorOrTextureType specular;
	CommonFloatOrParamType   shininess;
	CommonColorOrTextureType reflective;
	CommonFloatOrParamType   reflectivity;
	CommonColorOrTextureType transparent;
	CommonFloatOrParamType   transparency;
	CommonFloatOrParamType   index_of_refraction;	

	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "phong" );
	}
	out
	{
	
	}
	body
	{
	
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "emission"     : { emission.load( elem ); } break;
				case "ambient"      : { ambient.load( elem ); } break;
				case "diffuse"      : { diffuse.load( elem ); } break;
				case "specular"     : { specular.load( elem ); } break;
				case "shininess"    : { shininess.load( elem ); } break;
				case "reflective"   : { reflective.load( elem ); } break;
				case "reflectivity" : { reflectivity.load( elem ); } break;
				case "transparent"  : { transparent.load( elem ); } break;
				case "transparency" : { transparency.load( elem ); } break;
				case "index_of_refraction" : { index_of_refraction.load( elem ); } break;
				default : {} break;
			}
		}	
	}
}

struct Blinn
{

	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "blinn" );
	}
	out
	{
	
	}
	body
	{
	
	}
}
