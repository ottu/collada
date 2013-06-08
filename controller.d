module collada.controller;

import collada.base;
import collada.dataflow;

import std.algorithm;
import std.array;
import std.conv;

import adjustxml;

version( unittest )
{
	import std.stdio;
}

struct Targets
{

}

struct Skeleton
{

}

struct VertexWeights
{
	int count;
	
	InputB[] inputs;
	int[] vcount;
	int[] v;
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "vertex_weights" );
		assert( xml.attrs.length == 1 );
		assert( xml.attrs[0][0] == "count" );
		assert( xml.elems.length >= 2 );
	}
	out
	{
		assert( inputs.length >= 2 );
		assert( filter!( (a) => a.semantic == SEMANTICTYPE.JOINT )( inputs ).array.length == 1 );
	}
	body
	{
		count = xml.attrs[0][1].to!int;
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "input" :
				{
					InputB input;
					input.load( elem );
					inputs ~= input;
				} break;
				
				case "vcount" :
				{
					vcount = map!( (a) => a.to!int )( elem.texts ).array;
				} break;
				
				case "v" :
				{
					v = map!( (a) => a.to!int )( elem.texts ).array;
				} break;
				
				//case "extra" : {} break;
				
				default : { throw new Exception("VertexWeights element switch fault"); } break;
			}
		}
	
	}

}

struct Joints
{
	InputA[] inputs;
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "joints" );
		assert( xml.attrs.length == 0 );
		assert( xml.elems.length >= 2 );
	}
	out
	{
		assert( inputs.length >= 2 );
		//assert( reduce!( (a,b) => a && b.offset == -1 )( true, inputs ) );
		assert( filter!( (a) => a.semantic == SEMANTICTYPE.JOINT )( inputs ).array.length == 1 );
	}
	body
	{
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "input" :
				{
					InputA input;
					input.load( elem );
					inputs ~= input;
				
				} break;
				//case "extra" : {} break;
				default : { throw new Exception("Joints element switch fault"); } break;
			}
		}
	}

}

enum CONTROLLERTYPE : byte
{
	SKIN,
	MORPH,
	NONE
}

struct Skin
{
	string source;
	
	Float16 bind_shape_matrix;
	Source[] sources;
	Joints joints;
	VertexWeights vertex_weights;
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "skin" );
		assert( xml.attrs.length == 1 );
		assert( xml.attrs[0][0] == "source" );
		assert( xml.elems.length >= 5 );
	}
	out
	{
		assert( sources.length >= 3 );
	}
	body
	{
		source = xml.attrs[0][1];
		
		bind_shape_matrix = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0];
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "bind_shape_matrix" :
				{
					bind_shape_matrix.load( elem );
				} break;
			
				case "source" :
				{
					Source source;
					source.load( elem );
					sources ~= source;
				} break;				
				
				case "joints" :
				{
					joints.load( elem );
				} break;
				
				case "vertex_weights" :
				{
					vertex_weights.load( elem );
				} break;
				
				//case "extra" : {} break;
				default : { throw new Exception("Skin element switch fault"); } break;
			}
		}
	}
}

struct Morph
{

}

struct Controller
{
	string id;
	string name;
	
	//asset
	union
	{
		Skin skin;
		Morph morph;
	}
	CONTROLLERTYPE type = CONTROLLERTYPE.NONE;	
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "controller" );
	}
	out
	{
		assert( type != CONTROLLERTYPE.NONE );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr[0] )
			{
				case "id"   : { id   = attr[1]; } break;
				case "name" : { name = attr[1]; } break;
				default     : { throw new Exception("Controller attribute switch fault."); } break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				//case "asset"  : {} break;
				case "skin" : 
				{
					type = CONTROLLERTYPE.SKIN;
					skin.load( elem );
				} break;				
				
				//case "morph" :
				//{ 
				//	type = CONTROLLERTYPE.MORPH;
				//	morph.load( elem );
				//} break;
				//case "extra"  : {} break;
				
				default     : { throw new Exception("Controller element switch fault."); } break;
			}
		}
	}
}

struct LibraryControllers
{
	string id;
	string name;
	
	//asset
	Controller[] controllers;
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "library_controllers" );
	}
	out
	{
		assert( controllers.length >= 1 );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr[0] )
			{
				case "id"   : { id = attr[1]; } break;
				case "name" : { name = attr[1]; } break;
				default : { throw new Exception("LibraryControllers attribute switch fault"); } break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				//case "asset" : {} break;
				case "controller" :
				{
					Controller controller;
					controller.load( elem );
					controllers ~= controller;
				} break;				
				//case "extra" : {} break;
				default : { throw new Exception("LibraryControllers element switch fault"); } break;
			}
		}
	}
}

unittest
{
	writeln( "----- collada.controller.LibraryControllers unittest -----" );

	LibraryControllers lib;
	lib.load( parseXML( q{
	  <library_controllers>
		<controller id="skin">
		  <skin source="#base_mesh">
			<bind_shape_matrix>1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1</bind_shape_matrix>
			<source id="Joints">
			  <Name_array count="4">Root Spinel1 Spinel2 Head</Name_array>
			</source>
			<source id="Inv_bind_mats">
			  <float_array count="64">0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0</float_array>
			</source>
			<source id="Weights">
			  <float_array count="4"> 0.0 0.33 0.66 1.0 </float_array>
			</source>
			<joints>
			  <input semantic="JOINT" source="#Joints" />
			  <input semantic="INV_BIND_MATRIX" source="#Inv_bind_mats" />
			</joints>
			<vertex_weights count="4">
			  <input semantic="JOINT" source="#Joints" offset="0" />
			  <input semantic="WEIGHT" source="#Weights" offset="1" />
			  <vcount> 3 2 2 3 </vcount>
			  <v>-1 0 0 1 1 2 -1 3 1 4 -1 3 2 4 -1 0 3 1 2 2</v>
			</vertex_weights>
		  </skin>
		</controller>
	  </library_controllers>
	} ).root );
	
	assert( lib.controllers[0].skin.sources[1].floatArray.length == 64 );
	assert( lib.controllers[0].skin.sources[2].floatArray.length == 4 );
	
	writeln( "----- LibraryControllers done -----" );
}