module collada.transform;

import collada.base;

import std.conv : to;

version( unittest )
{
	import std.stdio;
	import std.algorithm;
	import std.array;
}

import adjustxml;

struct LookAt
{
	string sid;
	Float3 P;
	Float3 I;
	Float3 UP;
	
	FloatCount!(9) value;
	alias value this;
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == "lookat" );
		assert( xml.attrs.length <= 1 );
		assert( xml.elems.length == 0 );
		assert( xml.texts.length == 9 );
	}
	out
	{
		assert( P.isValid );
		assert( I.isValid );
		assert( UP.isValid );
		assert( value.isValid );
	}
	body
	{
		if( ( xml.attrs.length == 1 ) && ( xml.attrs[0][0] == "sid" ) )
			sid = xml.attrs[0][1];
	
		P  = [ xml.texts[0].to!float, xml.texts[1].to!float, xml.texts[2].to!float ];
		I  = [ xml.texts[3].to!float, xml.texts[4].to!float, xml.texts[5].to!float ];
		UP = [ xml.texts[6].to!float, xml.texts[7].to!float, xml.texts[8].to!float ];
		
		value = P ~ I ~ UP;
	}
}

unittest
{
	writeln( "----- collada.transform.LookAt unittest -----" );

	LookAt lookat;
	lookat.load( parseXML( q{
		<lookat>
			2.0 0.0 3.0
			0.0 0.0 0.0
			0.1 1.1 0.1
		</lookat>
	} ).root );
	
	assert( lookat.P[0].to!string == "2" );
	assert( lookat.P[1].to!string == "0" );
	assert( lookat.P[2].to!string == "3" );
	assert( lookat.I[0].to!string == "0" );
	assert( lookat.I[1].to!string == "0" );
	assert( lookat.I[2].to!string == "0" );
	assert( lookat.UP[0].to!string == "0.1" );
	assert( lookat.UP[1].to!string == "1.1" );
	assert( lookat.UP[2].to!string == "0.1" );
	
	writeln( "----- LookAt done -----" );
}

struct TransformType(int count, string name)
{
	string sid;
	
	FloatCount!(count) value;
	alias value this;
	
	void load( XMLValue xml )
	in
	{
		assert( xml.tag == name );
		assert( xml.attrs.length <= 1 );
		assert( xml.elems.length == 0 );
		assert( xml.texts.length == count );
	}
	out
	{
		assert( value.isValid );
	}
	body
	{
		if( ( xml.attrs.length == 1 ) && ( xml.attrs[0][0] == "sid" ) )
			sid = xml.attrs[0][1];
	
		foreach( i, text; xml.texts )
			value[i] = text.to!float;
	}
}

alias TransformType!( 16, "matrix"    ) Matrix;
alias TransformType!(  4, "rotate"    ) Rotate;
alias TransformType!(  3, "scale"     ) Scale;
alias TransformType!(  7, "skew"      ) Skew;
alias TransformType!(  3, "translate" ) Translate;

unittest
{
	writeln( "----- collada.transform.Matrix unittest -----" );

	Matrix matrix;
	matrix.load( parseXML( q{
		<matrix>
			1.0 0.0 0.0 2.0
			0.0 1.0 0.0 3.0
			0.0 0.0 1.0 4.0
			0.0 0.0 0.0 1.0
		</matrix>
	} ).root );
	
	assert( matrix[].map!( (a){ return a.to!int; } ).array == [ 1, 0, 0, 2, 0, 1, 0, 3, 0, 0, 1, 4, 0, 0, 0, 1 ] );
	
	writeln( "----- Matrix done -----" );
}

unittest
{
	writeln( "----- collada.transform.Rotate unittest -----" );

	Rotate rotate;
	rotate.load( parseXML( q{
		<rotate>
			0.0 1.0 0.0 90.0
		</rotate>
	} ).root );
	
	assert( rotate[].map!( (a){ return a.to!int; } ).array == [ 0, 1, 0, 90 ] );
	
	writeln( "----- Rotate done -----" );
}

unittest
{
	writeln( "----- collada.transform.Scale unittest -----" );

	Scale scale;
	scale.load( parseXML( q{
		<scale>
			2.0 2.0 2.0
		</scale>
	} ).root );
	
	assert( scale[].map!( (a){ return a.to!int; } ).array == [ 2, 2, 2 ] );
	
	writeln( "----- Scale done -----" );
}

unittest
{
	writeln( "----- collada.transform.Skew unittest -----" );

	Skew skew;
	skew.load( parseXML( q{
		<skew>
			45.0 0.0 1.0 0.0 1.0 0.0 0.0
		</skew>
	} ).root );
	
	assert( skew[].map!( (a){ return a.to!int; } ).array == [ 45, 0, 1, 0, 1, 0, 0 ] );
	
	writeln( "----- Skew done -----" );
}

unittest
{
	writeln( "----- collada.transform.Translate unittest -----" );

	Translate translate;
	translate.load( parseXML( q{
		<translate>
			10.0 0.0 0.0
		</translate>
	} ).root );
	
	assert( translate[].map!( (a){ return a.to!int; } ).array == [ 10, 0, 0 ] );
	
	writeln( "----- Translate done -----" );
}