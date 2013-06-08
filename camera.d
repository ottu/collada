module collada.camera;

import collada.base;

import std.algorithm;

import adjustxml;

version( unittest )
{ 
	import std.stdio;
	import std.conv : to;
}

enum CAMERATYPE : byte 
{
	ORTHOGRAPHIC,
	PERSPECTIVE,
	NONE
}

struct Orthographic
{
	SIDValue xmag;
	SIDValue ymag;
	SIDValue aspect_ratio;
	SIDValue znear;
	SIDValue zfar;
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "orthographic" );
	}
	out 
	{
		assert( ( aspect_ratio.isValid ) || ( xmag.isValid ) || ( ymag.isValid ) );
		assert( znear.isValid );
		assert( zfar.isValid );
	}
	body 
	{
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "xmag"         : { xmag.load( elem ); } break;
				case "ymag"         : { ymag.load( elem ); } break;
				case "aspect_ratio" : { aspect_ratio.load( elem ); } break;
				case "znear"        : { znear.load( elem ); } break;
				case "zfar"         : { zfar.load( elem ); } break;
				default : {} break;
			}
		}
	}

}

struct Perspective
{
	SIDValue xfov;
	SIDValue yfov;
	SIDValue aspect_ratio;
	SIDValue znear;
	SIDValue zfar;
	
	void load( XMLValue xml )
	in 
	{
		assert( xml.tag == "perspective" );
	}
	out 
	{
		assert( ( aspect_ratio.isValid ) || ( xfov.isValid ) || ( yfov.isValid ) );
		assert( znear.isValid );
		assert( zfar.isValid );
	}
	body 
	{
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "xfov"         : { xfov.load( elem ); } break;
				case "yfov"         : { yfov.load( elem ); } break;
				case "aspect_ratio" : { aspect_ratio.load( elem ); } break;
				case "znear"        : { znear.load( elem ); } break;
				case "zfar"         : { zfar.load( elem ); } break;
				default : {} break;
			}
		}
	}

}

struct TechniqueCommon
{
	union
	{
		Orthographic orthographic;
		Perspective  perspective;
	}
	
	CAMERATYPE type = CAMERATYPE.NONE;
	
	void load( XMLValue xml )
	in 
	{
		assert( xml.tag == "technique_common" );
		assert( xml.elems.length == 1 );
	}
	out 
	{
		assert( type != CAMERATYPE.NONE );
	}
	body 
	{
		switch( xml.elems[0].tag )
		{
			case "orthographic" :
			{
				type = CAMERATYPE.ORTHOGRAPHIC;
				orthographic.load( xml.elems[0] );
			} break;
			
			case "perspective" :
			{ 
				type = CAMERATYPE.PERSPECTIVE;
				perspective.load( xml.elems[0] ); 
			} break;
			
			default : {} break;
		}
	}
}

struct Technique
{
	
}
		
struct Optics
{

	TechniqueCommon common;
	//[] technique
	//[] extra
	
	void load( XMLValue xml )
	in 
	{
		assert( xml.tag == "optics" );
	}
	out 
	{
		assert( this.common.type != CAMERATYPE.NONE );
	}
	body 
	{
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

struct Camera
{
	string id;
	string name;
	
	//asset
	Optics optics;
	//imager
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "camera" );
	}
	out
	{
		assert( optics.common.type != CAMERATYPE.NONE );	
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr[0] )
			{
				case "id"   : { id   = attr[1]; } break;
				case "name" : { name = attr[1]; } break;
				default     : {} break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				case "asset"  : {} break;
				case "optics" : { optics.load( elem ); } break;				
				case "imager" : {} break;
				case "extra"  : {} break;
				default : {} break;
			}
		}
	}
}

struct LibraryCameras
{
	string id;
	string name;
	
	//asset
	Camera[] cameras;
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "library_cameras" );
	}
	out
	{
		assert( cameras.length > 0 );
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
				//case "asset" : {} break;
				case "camera" :
				{
					Camera camera;
					camera.load( elem );
					cameras ~= camera;
				
				} break;
				
				//case "extra" : {} break;
				default : { throw new Exception("LibraryCameras Element Switch fault"); } break;
			}
		}
	}
}

unittest
{
	writeln( "----- collada.camera.LibraryCameras unittest -----" );
	
	LibraryCameras libcams;
	libcams.load( parseXML( q{
		<library_cameras>
			<camera id="cl_unnamed_1" name="cl_unnamed_1">
				<optics>
					<technique_common>
						<perspective>
							<yfov>37.8493</yfov>
							<aspect_ratio>1</aspect_ratio>
							<znear>10</znear>
							<zfar>1000</zfar>
						</perspective>
					</technique_common>
				</optics>
			</camera>
		</library_cameras>
	} ).root );
	
	assert( libcams.cameras.length == 1 );
	assert( libcams.cameras[0].id == "cl_unnamed_1" );
	assert( libcams.cameras[0].name == "cl_unnamed_1" );	
	assert( libcams.cameras[0].optics.common.type == CAMERATYPE.PERSPECTIVE );
	assert( libcams.cameras[0].optics.common.perspective.yfov.value.to!string == "37.8493" );
	assert( libcams.cameras[0].optics.common.perspective.aspect_ratio.value.to!string == "1" ); 
	assert( libcams.cameras[0].optics.common.perspective.znear.value.to!string == "10" );
	assert( libcams.cameras[0].optics.common.perspective.zfar.value.to!string == "1000" );
		
	writeln( "----- LibraryCameras done -----" );
}
	
	