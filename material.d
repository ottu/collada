module collada.material;

import collada.base;
import collada.instance;

import std.algorithm;

import adjustxml;

version( unittest )
{
	import std.stdio;
	import std.conv : to;
}

struct Material
{
	string id;
	string name;
	
	//asset
	InstanceEffect effect;
	//[] extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "material" );
	}
	out
	{
		assert( effect.url != "" );
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
				case "asset"           : {} break;
				case "instance_effect" : { effect.load( elem ); } break;				
				case "extra"           : {} break;
				default : {} break;
			}
		}
	}
}

struct LibraryMaterials
{
	string id;
	string name;
	
	//asset
	Material[] materials;
	//[] extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "library_materials" );
	}
	out
	{
		assert( materials.length >= 1 );
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
				case "material" :
				{
					Material material;
					material.load( elem );
					materials ~= material;
				
				} break;
				
				case "extra" : {} break;
				default : {} break;
			}
		}
	}
}

unittest
{
	writeln( "----- collada.material.LibraryMaterials unittest -----" );
	
	LibraryMaterials lib;
	lib.load( parseXML( q{
		<library_materials>
			<material id="Blue" name="Blue">
				<instance_effect url="#Blue-fx"/>
			</material>
		</library_materials>
	} ).root );
	
	assert( lib.materials[0].id == "Blue" );
	assert( lib.materials[0].name == "Blue" );
	assert( lib.materials[0].effect.url == "#Blue-fx" );
	
	writeln( "----- LibraryMaterials done -----" );
}
