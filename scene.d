module collada.scene;

import collada.transform;
import collada.instance;

import std.string : tolower;

version( unittest )
{
	import std.stdio;
	import std.algorithm;
	import std.array;
	import std.conv;
}

import adjustxml;

enum NODETYPE : byte
{
	JOINT,
	NODE
}

struct Node
{
	template makeCode(string s, string t)
	{
		enum string makeCode = 
			s ~ " " ~ s.tolower ~ "; " ~
			s.tolower ~ ".load( elem ); " ~
			t ~ " ~= " ~ s.tolower ~ ";";
	}

	string id;
	string name;
	string sid;
	NODETYPE type = NODETYPE.NODE;
	//string[] layer;
	
	//asset
	LookAt[] lookats;
	Matrix[] matrixes;
	Rotate[] rotates;
	Scale[]  scales;
	Skew[]   skews;
	Translate[] translates;	
	
	InstanceCamera[]     instanceCameras;
	InstanceController[] instanceControllers;
	InstanceGeometry[]   instanceGeometries;
	InstanceLight[]      instanceLights;
	InstanceNode[]       instanceNodes;
	
	Node[] nodes;
	//[] extra;
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "node" );
	}
	out
	{
	
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr[0] )
			{
				case "id"   : { id = attr[1]; } break;
				case "name" : { name = attr[1]; } break;
				case "sid"  : { sid = attr[1]; } break;
				case "type" : 
				{
					switch( attr[1] )
					{
						case "NODE"  : { type = NODETYPE.NODE;  } break;
						case "JOINT" : { type = NODETYPE.JOINT; } break;
						default : { throw new Exception("Node type switch failed."); } break;
					}
				} break;
				
				//case "layer" : {} break;				
				default : { throw new Exception("Node attribute switch failed."); } break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "lookat" :{ mixin( makeCode!("LookAt", "lookats") ); } break;				
				case "matrix" : { mixin( makeCode!("Matrix", "matrixes") ); } break;
				case "rotate" : { mixin( makeCode!("Rotate", "rotates") ); } break;
				case "scale" : { mixin( makeCode!("Scale", "scales") ); } break;
				case "skew" : { mixin( makeCode!("Skew", "skews") ); } break;
				case "translate" : { mixin( makeCode!("Translate", "translates") ); } break;
				case "instance_camera" : { mixin( makeCode!("InstanceCamera", "instanceCameras") ); } break;
				case "instance_controller" : { mixin( makeCode!("InstanceController", "instanceControllers") ); } break;
				case "instance_geometry" : { mixin( makeCode!("InstanceGeometry", "instanceGeometries") ); } break;
				case "instance_light" : { mixin( makeCode!("InstanceLight", "instanceLights") ); } break;
				case "instance_node" : { mixin( makeCode!("InstanceNode", "instanceNodes") ); } break;
				case "node" : { mixin( makeCode!("Node", "nodes") ); } break;
				//case "extra" : {} break;				
				default : { throw new Exception("Node element switch failed."); } break;
			}
		}
		
	}
}

unittest
{
	Node node;
	node.load( parseXML( q{
		<node id="Camera" name="Camera">
			<translate sid="translate">-141.666 92.4958 296.3</translate>
			<rotate sid="rotateY">0 1 0 -26</rotate>
			<rotate sid="rotateX">1 0 0 -15.1954</rotate>
			<rotate sid="rotateZ">0 0 1 0</rotate>
			<instance_camera url="#cl_unnamed_1"/>
		</node>
	} ).root );
	
	assert( node.id == "Camera" );
	assert( node.name == "Camera" );
	assert( node.translates[0].sid == "translate" );
	assert( node.translates[0][].map!( (a){ return a.to!string; } ).array == [ "-141.666", "92.4958", "296.3" ] );
	assert( node.rotates[0].sid == "rotateY" );
	assert( node.rotates[0][].map!( (a){ return a.to!string; } ).array == [ "0", "1", "0", "-26" ] );
	assert( node.rotates[1].sid == "rotateX" );
	assert( node.rotates[1][].map!( (a){ return a.to!string; } ).array == [ "1", "0", "0", "-15.1954" ] );
	assert( node.rotates[2].sid == "rotateZ" );
	assert( node.rotates[2][].map!( (a){ return a.to!string; } ).array == [ "0", "0", "1", "0" ] );
	assert( node.instanceCameras[0].url == "#cl_unnamed_1" );
}

unittest
{
	Node node;
	node.load( parseXML( q{
		<node id="Box" name="Box">
			<rotate sid="rotateZ">0 0 1 0</rotate>
			<rotate sid="rotateY">0 1 0 0</rotate>
			<rotate sid="rotateX">1 0 0 0</rotate>
			<instance_geometry url="#box-lib">
				<bind_material>
					<technique_common>
						<instance_material symbol="BlueSG" target="#Blue"/>
						<instance_material symbol="RedSG" target="#Red"/>
					</technique_common>
				</bind_material>
			</instance_geometry>
		</node>
	} ).root );
	
	assert( node.instanceGeometries[0].url == "#box-lib" );
	assert( node.instanceGeometries[0].bindMaterial.common.instanceMaterials[0].symbol == "BlueSG" );
	assert( node.instanceGeometries[0].bindMaterial.common.instanceMaterials[0].target == "#Blue" );
	assert( node.instanceGeometries[0].bindMaterial.common.instanceMaterials[1].symbol == "RedSG" );
	assert( node.instanceGeometries[0].bindMaterial.common.instanceMaterials[1].target == "#Red" );
}

struct VisualScene
{
	string id;
	string name;
	//asset
	Node[] nodes;
	//[] evaluateScenes;
	//[] extra

	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "visual_scene" );
	}
	out
	{
		assert( nodes.length >= 1 );
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
				case "node" :
				{
					Node node;
					node.load( elem );
					nodes ~= node;
				
				} break;
				case "evaluate_scene" : {} break;
				case "extra" : {} break;
				default : {} break;
			}
		}
	}
}

struct LibraryVisualScenes
{
	string id;
	string name;

	//asset
	VisualScene[] visualScenes;
	//[]extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "library_visual_scenes" );
	}
	out
	{
		assert( visualScenes.length >= 1 );
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
				case "visual_scene" :
				{
					VisualScene visualScene;
					visualScene.load( elem );
					visualScenes ~= visualScene;
				
				} break;
				
				case "extra" : {} break;
				default : {} break;
			}
		}	
	}
}

unittest
{
	writeln( "----- collada.scene.LibraryVisualScene unittest -----" );

	LibraryVisualScenes lvs;
	lvs.load( parseXML( q{
		<library_visual_scenes>
			<visual_scene id="VisualSceneNode" name="untitled">	
				<node id="Camera" name="Camera">
					<translate sid="translate">-141.666 92.4958 296.3</translate>
					<rotate sid="rotateY">0 1 0 -26</rotate>
					<rotate sid="rotateX">1 0 0 -15.1954</rotate>
					<rotate sid="rotateZ">0 0 1 0</rotate>
					<instance_camera url="#cl_unnamed_1"/>
				</node>			
			</visual_scene>
		</library_visual_scenes>
	} ).root );
	
	
	
	writeln( "----- LibraryVisualScene done -----" );
}