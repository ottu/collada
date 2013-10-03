module collada.geometry;

import collada.dataflow;

import adjustxml;

version( unittest )
{
	import std.stdio;
}

struct Triangles
{
	string name;
	int count;
	string material;
	InputB[] inputs;
	int[] p;
	//extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "triangles" );
		assert( xml.attrs.length >= 1 );
	}
	out
	{
		assert( count > 0 );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "name" : { name = attr.value; } break;
				case "count" : { count = to!int(attr.value); } break;
				case "material" : { material = attr.value; } break;
				default : {} break;
			}
		}
		
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
				
				case "p" :
				{
					foreach( text; elem.texts )
						p ~= to!int(text);
				} break;
				
				case "extra" : {} break;
				default : {} break;
			}
		}
	
	}
}

struct Vertices
{
	string id;
	string name;
	InputA[] inputs;
	//extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "vertices" );
		assert( xml.attrs.length >= 1 );
		assert( xml.elems.length >= 1 );
	}
	out
	{
		assert( id != "" );
		assert( inputs.length >= 1 );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "id"   : { id   = attr.value; } break;
				case "name" : { name = attr.value; } break;
				default : {} break;			
			}
		}
		
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
				
				case "extra" : {} break;
				default : {} break;
			}
		}
	}
}

enum GEOMETRYTYPE : byte
{
	CONVEXMESH,
	MESH,
	SPLINE,
	BREP,
	NONE
}

struct ConvexMesh
{

	void load( XMLElement xml )
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

struct Mesh
{

	Source[] sources;
	Vertices vertices;
	//[] lines
	//[] linestrips
	//[] polygons
	//[] polylist
	Triangles[] triangles;
	//[] trifans
	//[] tristrips
	//[] extras

	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "mesh" );
		assert( xml.attrs.length == 0 );
		assert( xml.elems.length >= 2 );
	}
	out
	{
		assert( sources.length >= 1 );
		assert( vertices.id != "" );
	}
	body
	{
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "source" :
				{
					Source source;
					source.load( elem );
					sources ~= source;
				} break;
				
				case "vertices" : { vertices.load( elem ); } break;
				
				case "lines" : {} break;
				case "linestrips" : {} break;
				case "polygons" : {} break;
				case "polylist" : {} break;
				case "triangles" :
				{
					Triangles triangles_;
					triangles_.load( elem );
					triangles ~= triangles_;
				
				} break;
				case "trifans" : {} break;
				case "tristrips" : {} break;
				case "extra" : {} break;
				default : {} break;
			}
		}
	}

}

struct Spline
{

	void load( XMLElement xml )
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

struct Brep
{

	void load( XMLElement xml )
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

struct Geometry
{
	string id;
	string name;
	
	//asset
	
	union
	{
		ConvexMesh convexmesh;
		Mesh       mesh;
		Spline     spline;
		Brep       brep;
	}
	GEOMETRYTYPE type = GEOMETRYTYPE.NONE;
	
	//[] extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "geometry" );
	}
	out
	{
		assert( type != GEOMETRYTYPE.NONE );
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
				
				case "convex_mesh" :
				{
					type = GEOMETRYTYPE.CONVEXMESH;
					convexmesh.load( elem );
				} break;
				
				case "mesh" :
				{
					type = GEOMETRYTYPE.MESH;
					mesh.load( elem );				
				} break;
				
				case "spline" :
				{
					type = GEOMETRYTYPE.SPLINE;
					spline.load( elem );				
				} break;
				
				case "brep" : 
				{
					type = GEOMETRYTYPE.BREP;
					brep.load( elem );
				} break;
				
				case "extra"           : {} break;
				default : {} break;
			}
		}
	}
}

struct LibraryGeometries
{
	string id;
	string name;
	
	//asset
	Geometry[] geometries;
	//[] extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "library_geometries" );
	}
	out
	{
		assert( geometries.length >= 1 );
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
				case "geometry" :
				{
					Geometry geometry;
					geometry.load( elem );
					geometries ~= geometry;
				
				} break;
				
				case "extra" : {} break;
				default : {} break;
			}
		}
	}
}

unittest
{
	writeln( "----- collada.geometry.LibraryGeometries unittest -----" );

	LibraryGeometries lib;
	lib.load( parseXML( q{
		<library_geometries>
			<geometry id="box-lib" name="box">
				<mesh>
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
					<vertices id="box-lib-vertices">
						<input semantic="POSITION" source="#box-lib-positions"/>
					</vertices>
					<triangles count="2" material="RedSG">
						<input offset="0" semantic="VERTEX" source="#box-lib-vertices"/>
						<input offset="1" semantic="NORMAL" source="#box-lib-normals"/>
						<p>0 20 2 21 3 22 0 20 3 22 1 23</p>
					</triangles>
				</mesh>
			</geometry>
		</library_geometries>
	} ).root );
	
	assert( lib.geometries[0].id == "box-lib" );
	assert( lib.geometries[0].name == "box" );
	assert( lib.geometries[0].type == GEOMETRYTYPE.MESH );	
	//source unittest in collada.dataflow
	assert( lib.geometries[0].mesh.vertices.id == "box-lib-vertices" );
	//unshared input unittest in collada.dataflow
	assert( lib.geometries[0].mesh.triangles[0].count == 2 );
	assert( lib.geometries[0].mesh.triangles[0].material == "RedSG" );
	//input unittest in collada.dataflow
	assert( lib.geometries[0].mesh.triangles[0].p == [0, 20, 2, 21, 3, 22, 0, 20, 3, 22, 1, 23] );
	
	writeln( "----- LibraryGeometries done -----" );
}
