module collada.light;

import collada.base;

import std.algorithm;

import adjustxml;

version( unittest ) 
{ 
	import std.stdio; 
	import std.conv : to;
}

enum LIGHTTYPE : byte
{
	AMBIENT,
	DIRECTIONAL,
	POINT,
	SPOT,
	NONE
}

struct Ambient
{

	void load( XMLValue xml )
	in
	{
	
	}
	out
	{
	
	}
	body
	{
	
	}
}

struct Directional
{

	void load( XMLValue xml )
	in
	{
	
	}
	out
	{
	
	}
	body
	{
	
	}
}

struct Point
{
	Float3 color;
	SIDValue constant;
	SIDValue linear;
	SIDValue quadratic;
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "point" );
	}
	out
	{
		assert( color.isValid );
		assert( quadratic.isValid );
	}
	body
	{
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "color"                 : { color.load( elem ); } break;
				case "constant_attenuation"  : { constant.load( elem ); } break;
				case "linear_attenuation"    : { linear.load( elem ); } break;
				case "quadratic_attenuation" : { quadratic.load( elem ); } break;
				default : {} break;
			}
		}
	}

}

struct Spot
{

	void load( XMLValue xml )
	in
	{
	
	}
	out
	{
	
	}
	body
	{
	
	}
}

struct Common
{
	union
	{
		Ambient     ambient;
		Directional directional;
		Point       point;
		Spot        spot;
	}
	
	LIGHTTYPE type = LIGHTTYPE.NONE;
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "technique_common" );
		assert( xml.elems.length == 1 );
	}
	out
	{
		assert( type != LIGHTTYPE.NONE );
	}
	body
	{
		switch( xml.elems[0].tag )
		{
			case "ambient" :
			{
				type = LIGHTTYPE.AMBIENT;
				ambient.load( xml.elems[0] );
			} break;
			
			case "directional" :
			{ 
				type = LIGHTTYPE.DIRECTIONAL;
				directional.load( xml.elems[0] ); 
			} break;
			
			case "point" :
			{
				type = LIGHTTYPE.POINT;
				point.load( xml.elems[0] );			
			} break;
			
			case "spot" :
			{
				type = LIGHTTYPE.SPOT;
				spot.load( xml.elems[0] );
			} break;
			
			default : {} break;
		}
	}
}

struct Technique
{

}

struct Light
{
	string id;
	string name;
	
	//asset
	Common common;
	//[] technique
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "light" );
	}
	out
	{
		assert( common.type != LIGHTTYPE.NONE );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr[0] )
			{
				case "id"   : { id = attr[1]; } break;
				case "name" : { name = attr[1]; } break;
				default : {} break;
			}
		}
	
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "technique_common" : { common.load( elem ); } break;				
				case "technique"        : {} break;
				case "extra"            : {} break;
				default : {} break;
			}
		}
	}
}

struct LibraryLights
{
	string id;
	string name;
	
	//asset
	Light[] lights;
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "library_lights" );
	}
	out
	{
		assert( lights.length >= 1 );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr[0] )
			{
				case "id"   : { id = attr[1]; } break;
				case "name" : { name = attr[1]; } break;
				default : {} break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "asset" : {} break;
				case "light" :
				{
					Light light;
					light.load( elem );
					lights ~= light;
				
				} break;
				
				case "extra" : {} break;
				default : {} break;
			}
		}
	}
}

unittest
{
	writeln( "----- collada.light.LibraryLights unittest -----" );

	LibraryLights lib;
	lib.load( parseXML( q{
		<library_lights>
			<light id="Lt_Light-lib" name="Lt_Light">
				<technique_common>
					<point>
						<color>1 1 1</color>
						<constant_attenuation>1</constant_attenuation>
						<linear_attenuation>0</linear_attenuation>
						<quadratic_attenuation>0</quadratic_attenuation>
					</point>
				</technique_common>
			</light>
		</library_lights>
	} ).root );
	
	assert( lib.lights[0].id == "Lt_Light-lib" );
	assert( lib.lights[0].name == "Lt_Light" );
	assert( lib.lights[0].common.type == LIGHTTYPE.POINT );
	assert( lib.lights[0].common.point.color.value[0].to!string == "1" );
	assert( lib.lights[0].common.point.color.value[1].to!string == "1" );
	assert( lib.lights[0].common.point.color.value[2].to!string == "1" );
	assert( lib.lights[0].common.point.constant.value.to!string == "1" );
	assert( lib.lights[0].common.point.linear.value.to!string == "0" );
	assert( lib.lights[0].common.point.quadratic.value.to!string == "0" );
	
	writeln( "----- LibraryLights done -----" );
}