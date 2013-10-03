module collada.instance;

import collada.base;
import collada.dataflow;

import adjustxml;

struct InstanceType( string tagName )
{
	string sid;
	string name;
	string url;
	//[] extra;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == tagName );
		assert( xml.attrs.length >= 1 );
	}
	out
	{
		assert( url != "" );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "sid"  : { sid  = attr.value; } break;
				case "name" : { name = attr.value; } break;
				case "url"  : { url  = attr.value; } break;
				default : {} break;
			}
		}	
	}
}

alias InstanceType!("instance_camera") InstanceCamera;
alias InstanceType!("instance_light")  InstanceLight;
alias InstanceType!("instance_node")   InstanceNode;

struct BindVertexInput
{
	string semantic;
	string input_semantic;
	int    input_set;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "bind_vertex_input" );
		assert( xml.attrs.length >= 2 );
		assert( xml.elems.length == 0 );
	}
	out
	{
		assert( semantic != "" );
		assert( input_semantic != "" );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "semantic" : { semantic = attr.value; } break;
				case "input_semantic" : { input_semantic = attr.value; } break;
				case "input_set": { input_set = attr.value.to!int; } break;
				default : {} break;
			}
		}
	}
}

struct InstanceEffect
{
	string sid;
	string name;
	string url;
	
	//[] technique_hint
	//[] setparam
	//[] extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "instance_effect" );
		assert( xml.attrs.length == 1 );
		assert( xml.attrs[0].name == "url" );
	}
	out
	{
		assert( url != "" );
	}
	body
	{
		url = xml.attrs[0].value;	
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				//case "technique_hint" : {} break;
				//case "setparam" : {} break;
				//case "extra" : {} break;
				default : { throw new Exception("InstanceEffect element switch failed."); } break;
			}
		}
	}
}

struct InstanceMaterial
{
	string sid;
	string name;
	string target;
	string symbol;
	
	//Bind[] binds;
	BindVertexInput[] bind_vertex_inputs;
	//extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "instance_material" );
		assert( xml.attrs.length >= 2 );
	}
	out
	{
		assert( target != "" );
		assert( symbol != "" );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "sid"    : { sid    = attr.value; } break;
				case "name"   : { name   = attr.value; } break;
				case "target" : { target = attr.value; } break;
				case "symbol" : { symbol = attr.value; } break;
				default : {} break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "bind" : {} break;
				
				case "bind_vertex_input" :
				{
					BindVertexInput bvi;
					bvi.load( elem );
					bind_vertex_inputs ~= bvi;
				}
				
				case "extra" : {} break;
				default : {} break;
			}
		}
	}

}

struct TechniqueCommon
{
	InstanceMaterial[] instanceMaterials;

	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "technique_common" );
		assert( xml.attrs.length == 0 );
		assert( xml.elems.length >= 1 );
	}
	out
	{
		assert( instanceMaterials.length >= 1 );
	}
	body
	{
		foreach( elem; xml.elems )
		{
			InstanceMaterial im;
			im.load( elem );
			instanceMaterials ~= im;
		}
		
	}
}

struct BindMaterial
{
	Param[] params;
	TechniqueCommon common;
	//[] techniques;
	//[] extra;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "bind_material" );
		assert( xml.attrs.length == 0 );
		assert( xml.elems.length >= 1 );
	}
	out
	{
		assert( common.instanceMaterials.length > 0 );
	}
	body
	{
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "param" :
				{
					Param param;
					param.load( elem );
					params ~= param;				
				} break;
				
				case "technique_common" : {	common.load( elem );} break;				
				case "technique" : {} break;
				case "extra" : {} break;
				default : {} break;
			}
		}
	}
}

struct InstanceGeometry
{
	string sid;
	string name;
	string url;
	
	BindMaterial bindMaterial;
	//[] extra;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "instance_geometry" );
		assert( xml.attrs.length >= 1 );
	}
	out
	{
		assert( url != "" );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "sid"  : { sid  = attr.value; } break;
				case "name" : { name = attr.value; } break;
				case "url"  : { url  = attr.value; } break;
				default : {} break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "bind_material" : { bindMaterial.load( elem ); } break;
				case "extra" : {} break;
				default : {} break;
			}
		}
	}
}

struct InstanceController
{
	string sid;
	string name;
	string url;
	
	string[] skeletons;
	BindMaterial bindMaterial;
	//[] extra;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "instance_controller" );
		assert( xml.attrs.length >= 1 );
	}
	out
	{
		assert( url != "" );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "sid"  : { sid  = attr.value; } break;
				case "name" : { name = attr.value; } break;
				case "url"  : { url  = attr.value; } break;
				default : {} break;
			}
		}	
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "skeleton" :
				{
					skeletons ~= elem.texts[0];
				} break;
			
				case "bind_material" : { bindMaterial.load( elem );	} break;				
				case "extra" : {} break;
				default : {} break;
			}
		}
	}
}
