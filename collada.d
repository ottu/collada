module collada.collada;

import collada.animation;
import collada.camera;
import collada.controller;
import collada.effect;
import collada.geometry;
import collada.image;
import collada.light;
import collada.material;
import collada.scene;

import std.stdio;
import std.algorithm;

import adjustxml;

class Collada
{

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

	this() { }	
	~this() { }
	
	void load( XMLValue xml )
	{
		XMLValue[] vals = [];
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_animations"; } );
		if( vals.length > 0 ) { writeln("animations"); libAnimations.load( vals[0] ); }
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_cameras"; } );
		if( vals.length > 0 ) { writeln("cameras"); libCameras.load( vals[0] ); }
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_controllers"; } );
		if( vals.length > 0 ) { writeln("controller"); libControllers.load( vals[0] ); }
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_effects"; } );
		if( vals.length > 0 ) { writeln("effects"); libEffects.load( vals[0] ); }
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_geometries"; } );
		if( vals.length > 0 ) { writeln("geometries"); libGeometries.load( vals[0] ); }
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_images"; } );
		if( vals.length > 0 ) { writeln("images"); libImages.load( vals[0] ); }
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_lights"; } );
		if( vals.length > 0 ) { writeln("lights"); libLights.load( vals[0] ); }
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_materials"; } );
		if( vals.length > 0 ) { writeln("materials"); libMaterials.load( vals[0] ); }
		
		vals = xml.elems.find!( (elem){ return elem.tag == "library_visual_scenes"; } );
		if( vals.length > 0 ) { writeln("visual_scene"); libVisualScenes.load( vals[0] ); }
		
	}

}

unittest
{
	writeln("----- collada.Collada unittest -----");
	Collada collada = new Collada;
	//collada.load( parseXML( import("multimtl_triangulate.dae") ).root );
	//collada.load( parseXML( import("Appearance_Miku.dae") ).root );
	
	writeln("----- Collada done -----");
}