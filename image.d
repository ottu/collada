module collada.image;

import collada.base;

import adjustxml;

version( unittest )
{
	import std.stdio;
}

enum IMAGETYPE : byte
{
	DATA,
	INITFROM,
	NONE
}

struct Image
{
	string id;
	string name;
	string format;
	uint height;
	uint width;
	uint depth;
	
	//asset
	//union
	//{
	//	string data
		string initFrom;
	//}
	IMAGETYPE type = IMAGETYPE.NONE;
	//imager
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "image" );
	}
	out
	{
		assert( type != IMAGETYPE.NONE );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr[0] )
			{
				case "id"   : { id   = attr[1]; } break;
				case "name" : { name = attr[1]; } break;
				default     : { throw new Exception("Image attribute switch fault."); } break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				//case "asset"  : {} break;
				//case "data" : {} break;				
				case "init_from" :
				{ 
					type = IMAGETYPE.INITFROM;
					initFrom = elem.texts[0];
				} break;
				//case "extra"  : {} break;
				default     : { throw new Exception("Image element switch fault."); } break;
			}
		}
	}
}

struct LibraryImages
{
	string id;
	string name;
	
	//asset
	Image[] images;
	//[] extra
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "library_images" );
	}
	out
	{
		assert( images.length > 0 );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr[0] )
			{
				case "id"   : { id = attr[1]; } break;
				case "name" : { name = attr[1]; } break;
				default : { throw new Exception("LibraryImages attribute switch fault"); } break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				//case "asset" : {} break;
				case "image" :
				{
					Image image;
					image.load( elem );
					images ~= image;
				} break;				
				//case "extra" : {} break;
				default : { throw new Exception("LibraryImages element switch fault"); } break;
			}
		}
	}
}

unittest
{
	writeln( "----- collada.light.LibraryImages unittest -----" );

	LibraryImages lib;
	lib.load( parseXML( q{
		<library_images>
			<image id="Image-00">
				<init_from>huku3.bmp</init_from>
			</image>
			<image id="Image-01">
				<init_from>huku1.bmp</init_from>
			</image>
			<image id="Image-02">
				<init_from>kami.bmp</init_from>
			</image>
			<image id="Image-03">
				<init_from>kami_ol.bmp</init_from>
			</image>
			<image id="Image-04">
				<init_from>heltudofon.bmp</init_from>
			</image>
			<image id="Image-05">
				<init_from>huku3w.bmp</init_from>
			</image>
			<image id="Image-06">
				<init_from>me.bmp</init_from>
			</image>
			<image id="Image-07">
				<init_from>hoho.png</init_from>
			</image>
	    </library_images>
	} ).root );
	
	assert( lib.images.length == 8 );
	assert( lib.images[0].id == "Image-00" );
	assert( lib.images[0].initFrom == "huku3.bmp" );
	
	writeln( "----- LibraryImages done -----" );
}