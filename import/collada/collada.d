module collada.collada;

public
{
    import collada.animation;
    import collada.camera;
    import collada.controller;
    import collada.effect;
    import collada.geometry;
    import collada.image;
    import collada.light;
    import collada.material;
    import collada.scene;
    import collada.utils;
}

import std.stdio;
import std.algorithm;
import std.file;

template GenLoader( T )
{
     immutable GenLoader = ( T lib, string name ) => "
        vals = elems.find!( elem => elem.getName == \"" ~ name ~ "\" );
        if( vals.length > 0 ) { writeln( " ~ name ~ " ); " ~ lib.stringof ~ ".load( vals[0] ); }
    ";
}

string Gen( string lib, string name )
{
    return "vals = elems.find!( elem => elem.getName ==\"" ~ name ~ "\" );" ~
           "if( vals.length > 0 ) { writeln( \"" ~ name ~ "\" ); " ~ lib ~ ".load( vals[0] ); }";
}

class Collada
{
    XmlNode _self;

	//asset
	LibraryAnimations   libAnimations;
	LibraryCameras      libCameras;
	LibraryControllers  libControllers;
	LibraryEffects      libEffects;
	LibraryGeometries   libGeometries;
	LibraryImages       libImages;
	LibraryLights       libLights;
	LibraryMaterials    libMaterials;
	LibraryVisualScenes libVisualScenes;
	//[] extra

	this( string filePath )
    {
        XmlDocument doc = XmlDocument( readText( filePath ) );
        _self = doc.getElements[0];

        auto elems = _self.getElements;
        XmlNode[] vals = [];

        mixin( Gen( "libAnimations",   "library_animations" ) );
        //mixin( GenLoader!( libCameras,      "library_cameras" ) );
        //mixin( GenLoader!( libControllers,  "library_controllers" ) );
        //mixin( GenLoader!( libEffects,      "library_effects" ) );
        //mixin( GenLoader!( libGeometries,   "library_geometries" ) );
        //mixin( GenLoader!( libImages,       "library_images" ) );
        //mixin( GenLoader!( libLights,       "library_lights" ) );
        //mixin( GenLoader!( libMaterials,    "library_materials" ) );
        //mixin( GenLoader!( libVisualScenes, "library_visual_scenes" ) );
    }	
	
    ~this() { }

}

unittest
{
	writeln("----- collada.Collada unittest -----");
	//Collada collada = new Collada;
	//collada.load( parseXML( import("multimtl_triangulate.dae") ).root );
	//collada.load( parseXML( import("Appearance_Miku.dae") ).root );
	
	writeln("----- Collada done -----");
}
