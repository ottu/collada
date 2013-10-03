module collada.dataflow;

import std.algorithm;

version( unittest )
{
	import std.stdio;
	import std.array;
	import std.conv : to;
}

import adjustxml;

struct TypeArray(T) if ( is(T == int) || is(T == float) || is(T == bool) || is(T == string) )
{
	int count;
	string id;
	string name;
	//digits
	//magnitude
	T[] value;
	alias value this;
	
	void load( XMLElement xml )
	in
	{
		string type = is( T == string ) ? "Name" : T.stringof;
		assert( xml.tag == type ~ "_array" );
		assert( xml.elems.length == 0 );
	}
	out
	{
		assert( count > 0 );
		assert( value.length == count );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "count" : { count = to!int(attr.value); } break;
				case "id"    : { id    = attr.value; } break;
				case "name"  : { name  = attr.value; } break;
				case "digits"    : {} break;
				case "magnitude" : {} break;
				default : {} break;
			}
		}
		
		foreach( text; xml.texts )
			value ~= to!T(text);
	
	}	
}

alias TypeArray!(int)    IntArray;
alias TypeArray!(float)  FloatArray;
alias TypeArray!(bool)   BoolArray;
alias TypeArray!(string) NameArray;

enum ARRAYTYPE : byte
{	
	BOOL,	
	FLOAT,
//	IDREF,
	INT,
	NAME,
//	SIDREF,
//	TOKEN,
	NONE
}

struct Param
{
	string name;
	string sid;
	ARRAYTYPE type = ARRAYTYPE.NONE;
	string semantic;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "param" );
		assert( xml.attrs.length >= 1 );
	}
	out
	{
		assert( type != ARRAYTYPE.NONE );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "name" : { name = attr.value; } break;
				case "sid"  : { sid = attr.value; } break;
				case "type" :
				{
					switch( attr.value )
					{
						case "Name"  : { type = ARRAYTYPE.NAME; } break;
						case "bool"  : { type = ARRAYTYPE.BOOL; } break;
						case "int"   : { type = ARRAYTYPE.INT;  } break;
						case "float" :
						case "float4x4" : { type = ARRAYTYPE.FLOAT; } break;
						default : { throw new Exception( "Param type switch faild." ); } break;
					}
				} break;
				case "semantic" : { semantic = attr.value; } break;
				default : { throw new Exception( "Param attribute switch faild." ); } break;
			}
		}	
	}
}

struct Accessor
{
	int count;
	int offset;
	string source;
	int stride = 1;
	Param[] params;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "accessor" );
		assert( xml.attrs.length >= 2 );
	}
	out
	{
		assert( count > 0 );
		assert( source != "" );
	}
	body
	{
		foreach( attr; xml.attrs )		
		{
			switch( attr.name )
			{
				case "count" : { count = to!int(attr.value); } break;
				case "offset" : { offset = to!int(attr.value); } break;
				case "source" :	{ source = attr.value; } break;
				case "stride" : { stride = to!int(attr.value); } break;
				default : {} break;
			}
		}	
		
		foreach( elem; xml.elems )
		{
			Param param;
			param.load( elem );
			params ~= param;
		}
	}	
}

struct TechniqueCommon
{
	Accessor accessor;

	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "technique_common" );
		assert( xml.elems.length == 1 );
	}
	out
	{
		assert( accessor.source != "" );
	}
	body
	{
		accessor.load( xml.elems[0] );
	}

}

struct Technique
{

}

struct Source
{
	string id;
	string name;
	
	//asset
	union
	{
		IntArray   intArray;
		FloatArray floatArray;
		BoolArray  boolArray;
		NameArray  nameArray;
	}
	ARRAYTYPE type = ARRAYTYPE.NONE;
	
	TechniqueCommon common;
	Technique[] techniques;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "source" );
		assert( xml.attrs.length >= 1 );
	}
	out
	{
		assert( id != "" );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "id"   : { id = attr.value; } break;
				case "name" : { name = attr.value; } break;
				default : {} break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "asset" : {} break;
				
				case "bool_array" :
				{
					type = ARRAYTYPE.BOOL;
					boolArray.load( elem );				
				} break;
				
				case "float_array" :
				{
					type = ARRAYTYPE.FLOAT;
					floatArray.load( elem );
				
				} break;
				
				//case "IDREF_array" : {} break;
				
				case "int_array" :
				{
					type = ARRAYTYPE.INT;
					intArray.load( elem );
				} break;
				
				case "Name_array" : 
				{
					type = ARRAYTYPE.NAME;
					nameArray.load( elem );
				} break;
				
				//case "SIDREF_array" : {} break;
				
				//case "token_array" : {} break;
				
				case "technique_common" :
				{
					common.load( elem );
				} break;
				
				//case "technique" : {} break;
				
				default : {} break;
				
				
			}
		}
	
	}
	
}

unittest
{
	writeln( "----- collada.dataflow.Source unittest -----" );

	Source source;
	source.load( parseXML( q{
		<source id="box-lib-positions" name="position">
			<float_array count="24" id="box-lib-positions-array">-50 50 50 50 50 50 -50 -50 50 50 -50 50 -50 50 -50 50 50 -50 -50 -50 -50 50 -50 -50</float_array>
			<technique_common>
				<accessor count="8" offset="0" source="#box-lib-positions-array" stride="3">
					<param name="X" type="float"/>
					<param name="Y" type="float"/>
					<param name="Z" type="float"/>
				</accessor>
			</technique_common>
		</source>
	} ).root );
	
	assert( source.id == "box-lib-positions" );
	assert( source.name == "position" );
	assert( source.type == ARRAYTYPE.FLOAT );
	assert( source.floatArray.count == 24 );
	assert( source.floatArray.id =="box-lib-positions-array" );
	assert( source.floatArray.value == [ -50,  50,  50,
										  50,  50,  50,
										 -50, -50,  50,
										  50, -50,  50,
										 -50,  50, -50,
										  50,  50, -50,
										 -50, -50, -50,
										  50, -50, -50] );
	
	assert( source.common.accessor.count == 8 );
	assert( source.common.accessor.offset == 0 );
	assert( source.common.accessor.source == "#box-lib-positions-array" );
	assert( source.common.accessor.stride == 3 );
	assert( source.common.accessor.params.length == 3 );
	assert( source.common.accessor.params[0].name == "X" );
	assert( source.common.accessor.params[0].type == ARRAYTYPE.FLOAT );
	assert( source.common.accessor.params[1].name == "Y" );
	assert( source.common.accessor.params[1].type == ARRAYTYPE.FLOAT );
	assert( source.common.accessor.params[2].name == "Z" );
	assert( source.common.accessor.params[2].type == ARRAYTYPE.FLOAT );		
	
	writeln( "----- Source done -----" );
}

enum SEMANTICTYPE : byte
{
	BINORMAL,
	COLOR,
	CONTINUITY,
	IMAGE,
	INPUT,
	IN_TANGENT,
	INTERPOLATION,
	INV_BIND_MATRIX,
	JOINT,
	LINEAR_STEPS,
	MORPH_TARGET,
	MORPH_WEIGHT,
	NORMAL,
	OUTPUT,
	OUT_TANGENT,
	POSITION,
	TANGENT,
	TEXBINORMAL,
	TEXCOORD,
	TEXTANGENT,
	UV,
	VERTEX,
	WEIGHT,
	NONE
}

enum INPUTTYPE : byte
{
	A, 
	B
}

struct Input(INPUTTYPE type)
{
	static if( type == INPUTTYPE.B )
	{
	int offset = -1;
	int set;
	}
	
	SEMANTICTYPE semantic = SEMANTICTYPE.NONE;
	string source;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "input" );
		
		static if( type == INPUTTYPE.A )
		assert( xml.attrs.length >= 2 );
		else if( type == INPUTTYPE.B )
		assert( xml.attrs.length >= 3 );
		
		assert( xml.elems.length == 0 );
	}
	out
	{
		assert( semantic != SEMANTICTYPE.NONE );
		assert( source != "" );
		
		static if( type == INPUTTYPE.B )
		{
		assert( offset != -1 ); 
		}
		
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				static if( type == INPUTTYPE.B )
				{
				case "offset" : { offset = to!int( attr.value ); } break;
				case "set"    : { set = to!int( attr.value ); } break;
				}
				
				case "semantic" :
				{				
					switch( attr.value )
					{
						case "BINORMAL"        : { semantic = SEMANTICTYPE.BINORMAL; } break;
						case "COLOR"           : { semantic = SEMANTICTYPE.COLOR; } break;
						case "CONTINUITY"      : { semantic = SEMANTICTYPE.CONTINUITY; } break;
						case "IMAGE"           : { semantic = SEMANTICTYPE.IMAGE; } break;
						case "INPUT"           : { semantic = SEMANTICTYPE.INPUT; } break;
						case "IN_TANGENT"      : { semantic = SEMANTICTYPE.IN_TANGENT; } break;
						case "INTERPOLATION"   : { semantic = SEMANTICTYPE.INTERPOLATION; } break;
						case "INV_BIND_MATRIX" : { semantic = SEMANTICTYPE.INV_BIND_MATRIX; } break;
						case "JOINT"           : { semantic = SEMANTICTYPE.JOINT; } break;
						case "LINEAR_STEPS"    : { semantic = SEMANTICTYPE.LINEAR_STEPS; } break;
						case "MORPH_TARGET"    : { semantic = SEMANTICTYPE.MORPH_TARGET; } break;
						case "MORPH_WEIGHT"    : { semantic = SEMANTICTYPE.MORPH_WEIGHT; } break;
						case "NORMAL"          : { semantic = SEMANTICTYPE.NORMAL; } break;
						case "OUTPUT"          : { semantic = SEMANTICTYPE.OUTPUT; } break;
						case "OUT_TANGENT"     : { semantic = SEMANTICTYPE.OUT_TANGENT; } break;
						case "POSITION"        : { semantic = SEMANTICTYPE.POSITION; } break;
						case "TANGENT"         : { semantic = SEMANTICTYPE.TANGENT; } break;
						case "TEXBINORMAL"     : { semantic = SEMANTICTYPE.TEXBINORMAL; } break;
						case "TEXCOORD"        : { semantic = SEMANTICTYPE.TEXCOORD; } break;
						case "TEXTANGENT"      : { semantic = SEMANTICTYPE.TEXTANGENT; } break;
						case "UV"              : { semantic = SEMANTICTYPE.UV; } break;
						case "VERTEX"          : { semantic = SEMANTICTYPE.VERTEX; } break;
						case "WEIGHT"          : { semantic = SEMANTICTYPE.WEIGHT; } break;
						default : { throw new Exception( "Input semantic switch [" ~ attr.value ~ "] failed." ); } break;						 
					}
				} break;		
			
				case "source" : { source   = attr.value; } break;
				
				default : { throw new Exception( "Input element switch failed." ); } break;
			}
		}
	}

}

alias Input!(INPUTTYPE.A) InputA;
alias Input!(INPUTTYPE.B) InputB;
