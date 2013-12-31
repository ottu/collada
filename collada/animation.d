module collada.animation;

import collada.dataflow;

import adjustxml;

version( unittest )
{
	import std.stdio;
}

struct Channel
{
	string source;
	string target;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "channel" );
		assert( xml.attrs.length == 2 );
		assert( xml.elems.length == 0 );
	}
	out
	{
		assert( source != "" );
		assert( target != "" );
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "source" : { source = attr.value; } break;
				case "target" : { target = attr.value; } break;
				default : { throw new Exception( "Channel attribute switch failed." );} break;
			}
		}
	}
	
}

struct Sampler
{
	string id;
	
	InputA[] inputs;
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "sampler" );
		assert( xml.attrs.length <= 1 );
		assert( xml.elems.length >= 1 );
	}
	out
	{
		assert( inputs.length >= 1 );
	}
	body
	{
		if( ( xml.attrs.length == 1 ) && ( xml.attrs[0].name == "id" ) )
			id = xml.attrs[0].value;
			
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
				
				default : { throw new Exception( "Sampler element switch failed." ); } break;
			}
		}
			
	}

}

struct Animation
{
	string id;
	string name;
	
	//asset
	Animation[] animations;
	Source[]    sources;
	Sampler[]   samplers;
	Channel[]   channels;
	//[] extra	
		
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "animation" );
	}
	out
	{
		assert(
			( animations.length >= 1 )
			||
			(
				( samplers.length >= 1 )
				&&
				( channels.length >= 1 )
				&&
				( samplers.length == channels.length )
			)
		);
	
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "id" : { id = attr.value; } break;
				case "name" : { name = attr.value; } break;
				default : { throw new Exception( "Animation attribute switch failed." ); } break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				//case "asset" : {} break;
				case "animation" :
				{
					Animation animation;
					animation.load( elem );
					animations ~= animation;
				} break;
				
				case "source" :
				{
					Source source;
					source.load( elem );
					sources ~= source;
				} break;
				
				case "sampler" :
				{
					Sampler sampler;
					sampler.load( elem );
					samplers ~= sampler;
				} break;
				
				case "channel" :
				{
					Channel channel;
					channel.load( elem );
					channels ~= channel;
				} break;
				
				//case "extra" : {} break;
				default : { throw new Exception( "Animation element switch failed." ); } break;
			}
		}
	}

}

struct LibraryAnimations
{
	string id;
	string name;
	
	//asset
	Animation[] animations;
	//[] extra
	
	void load( XMLElement xml )
	in
	{
		assert( xml.tag == "library_animations");
		assert( xml.elems.length >= 1 );
	}
	out
	{
		assert( animations.length >= 1 );		
	}
	body
	{
		foreach( attr; xml.attrs )
		{
			switch( attr.name )
			{
				case "id" : { id = attr.value; } break;
				case "name" : { name = attr.value; } break;
				default : { throw new Exception( "LibraryAnimations attribute switch failed." ); } break;
			}
		}
		
		foreach( elem; xml.elems )
		{
			switch( elem.tag )
			{
				//case "asset" : {} break;
				case "animation" :
				{
					Animation animation;
					animation.load( elem );
					animations ~= animation;
				} break;
				//case "extra" : {} break;
				default : { throw new Exception( "LibraryAnimations element switch failed." ); } break;
			}
		}
	}

}
