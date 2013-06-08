module collada.modelutils;

import std.math;
import std.algorithm;

version( unittest ) {
    import std.stdio;
    import std.array;
    import std.conv;
}

//float clamp( const float value, const float min, const float max )
auto ref clamp( const float value, const float min, const float max )
{
    if (value < min) return min;
    if (value > max) return max;         
    return value;
}

unittest
{
    assert( clamp( 0.5, 0.0, 1.0 ) == 0.5 );
    assert( clamp( -0.5, 0.0, 1.0 ) == 0.0 );
    assert( clamp( 1.5, 0.0, 1.0 ) == 1.0 );
}

/+ --------------------
   Vector3
   -------------------- +/
struct Vector3
{
    float[3] value;
    alias value this;
}

//Vector3 Lerp( ref const Vector3 l, ref const Vector3 r, ref const float t )
auto ref Lerp( Vector3 l, Vector3 r, float t )
{
    float t1 = t;
    float t0 = 1 - t;
    
    Vector3 result;
    
    result[0] = ( l[0] * t0 ) + ( r[0] * t1 );
    result[1] = ( l[1] * t0 ) + ( r[1] * t1 );
    result[2] = ( l[2] * t0 ) + ( r[2] * t1 );
    
    return result;
}

void normalize( ref Vector3 mat )
{
    if( mat == [ 0.0, 0.0, 0.0 ] ) return;

    float s = sqrt( mat[0]*mat[0] + mat[1]*mat[1] + mat[2]*mat[2] );
    auto f = 1 / s;
    foreach( ref a; mat )
        a *= f;
    
    //assert( s > 0.0 );
    //foreach( ref a; mat )
    //    a /= s;
}
    
unittest
{
    
    int[3] test( ref const Vector3 vec )
    {
        return[ (vec[0] / 0.000001).to!int, (vec[1] / 0.000001).to!int, (vec[2] / 0.000001).to!int ];
    }
    
    Vector3 vector;
    vector = [ 0.0, 0.0, -15.0 ];
    normalize( vector );
    assert( vector == [ 0.0, 0.0, -1.0 ] );
    
    vector = [ 0.0, 0.0, 15.0 ];
    normalize( vector );
    assert( vector == [ 0.0, 0.0, 1.0 ] );
    
    vector = [ -1.0, -2.0, -3.0 ];
    normalize( vector );
    //vector == [ -0.267261, -0.534522, -0.801783 ]
    assert( test( vector ) == [ -267261, -534522, -801783 ] );
    
    vector = [ 1.0, -1.0, 1.0 ];
    normalize( vector );
    assert( test( vector ) == [ 577350, -577350, 577350 ] );
    
    vector = [ -1.0, -1.0, -1.0 ];
    normalize( vector );
    assert( test( vector ) == [ -577350, -577350, -577350 ] );
    
    vector = [ -1.0, 1.0, -1.0 ];
    normalize( vector );
    assert( test( vector ) == [ -577350, 577350, -577350 ] );
    
    
    
}

//Vector3 cross( ref const Vector3 v1, ref const Vector3 v2 )
auto ref cross( Vector3 v1, Vector3 v2 )
{
    return Vector3( [ (v1[1]*v2[2])-(v1[2]*v2[1]),
                      (v1[2]*v2[0])-(v1[0]*v2[2]),
                      (v1[0]*v2[1])-(v1[1]*v2[0]) ] );
}
    
unittest
{
    Vector3 v1, v2;
    v1 = [ 1.0, 4.0, 0.0 ]; v2 = [ 4.0, 1.0, 0.0 ];
    assert( cross( v1, v2 ) == [ 0.0, 0.0, -15.0 ] );
    v1 = [ 4.0, 1.0, 0.0 ]; v2 = [ 1.0, 4.0, 0.0 ];
    assert( cross( v1, v2 ) == [ 0.0, 0.0,  15.0 ] );
    v1 = [ 3.0, 3.0, 1.5 ]; v2 = [ 3.0, 3.0, -1.5 ];
    assert( cross( v1, v2 ) == [ -9.0, 9.0, 0.0 ] );
    v1 = [ 3.0, 3.0, -1.5 ]; v2 = [ 3.0, 3.0, 1.5 ];
    assert( cross( v1, v2 ) == [ 9.0, -9.0, 0.0 ] );
}
    
//float dot( ref const Vector3 v1, ref const Vector3 v2 )
auto ref dot( Vector3 v1, Vector3 v2 )
{
    return ( (v1[0]*v2[0]) + (v1[1]*v2[1]) + (v1[2]*v2[2]) );
}

unittest
{
    Vector3 v1, v2;
    v1 = [ 1.1, 2.2, 3.3 ];
    v2 = [ -4.4, 5.5, -6.6 ];
    //assert( dot( v1, v2 ) == -14.52 );

    v1 = [ 1.0, 0.0, 0.0 ];
    v2 = [ 0.0, 1.0, 0.0 ];
    assert( dot( v1, v2 ) == 0.0 );
    
    v1 = [ 1.0, 0.0, 0.0 ];
    v2 = [ 1.0, 1.0, 0.0 ];
    assert( dot( v1, v2 ) == 1.0 );

    v1 = [ -1.0, 0.0, 0.0 ];
    v2 = [ -1.0, -1.0, 0.0 ];
    assert( dot( v1, v2 ) == 1.0 );

    v1 = [ 1.0, 0.0, 0.0 ];
    v2 = [ -1.0, 1.0, 0.0 ];
    assert( dot( v1, v2 ) == -1.0 );
}

//Vector3 subtract( ref const Vector3 l, ref const Vector3 r )
auto ref subtract( Vector3 l, Vector3 r )
{
    return Vector3( [ l[0]-r[0], l[1]-r[1], l[2]-r[2] ] );
}

unittest
{
    Vector3 v1, v2;
    v1 = [ 3.0, 3.0, 3.0 ];
    v2 = [ 2.0, 2.0, 2.0 ]; 
    assert( subtract( v1, v2 ) == [ 1.0, 1.0, 1.0 ] );
}

//Vector3 multMatrix3x3( ref const Vector3 vec, ref const Matrix3x3 mat )
auto ref multMatrix3x3( Vector3 vec, Matrix3x3 mat )
{
    return Vector3( [ vec[0]*mat[0] + vec[1]*mat[3] + vec[2]*mat[6],
                      vec[0]*mat[1] + vec[1]*mat[4] + vec[2]*mat[7],
                      vec[0]*mat[2] + vec[1]*mat[5] + vec[2]*mat[8] ] );
}

unittest
{
    Vector3   vec = Vector3( [ 1, 2, 3 ] );
    Matrix3x3 mat = Matrix3x3( [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] );
    
    assert( vec.multMatrix3x3( mat ) == [ 30, 36, 42 ] );
}

/+ --------------------
   Matrix3x3
   -------------------- +/
struct Matrix3x3
{
    float[9] value;
    alias value this;
}

immutable Matrix3x3 identity3x3 = Matrix3x3( [ 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0 ] );

//Matrix3x3 transpose( ref const Matrix3x3 mat )
auto ref transpose( Matrix3x3 mat )
{
    return Matrix3x3( [ mat[0], mat[3], mat[6], mat[1], mat[4], mat[7], mat[2], mat[5], mat[8] ] );
}

unittest
{
    Matrix3x3 matrix = Matrix3x3( [ 0, 1, 2, 3, 4, 5, 6, 7, 8 ] );
    assert( matrix.transpose == [ 0, 3, 6, 1, 4, 7, 2, 5, 8 ] );
}

//Matrix3x3 inverse( ref const Matrix3x3 mat )
auto ref inverse( Matrix3x3 mat )
{
    float det = + (mat[0]*mat[4]*mat[8]) + (mat[3]*mat[7]*mat[2]) + (mat[6]*mat[1]*mat[5])
                - (mat[0]*mat[7]*mat[5]) - (mat[6]*mat[4]*mat[2]) - (mat[3]*mat[1]*mat[8]);
    
    Matrix3x3 result;
    result[0] = ( (mat[4]*mat[8]) - (mat[5]*mat[7]) ) / det;
    result[1] = ( (mat[7]*mat[2]) - (mat[8]*mat[1]) ) / det;
    result[2] = ( (mat[1]*mat[5]) - (mat[2]*mat[4]) ) / det;
    result[3] = ( (mat[5]*mat[6]) - (mat[3]*mat[8]) ) / det;
    result[4] = ( (mat[8]*mat[0]) - (mat[6]*mat[2]) ) / det;
    result[5] = ( (mat[2]*mat[3]) - (mat[0]*mat[5]) ) / det;
    result[6] = ( (mat[3]*mat[7]) - (mat[4]*mat[6]) ) / det;
    result[7] = ( (mat[6]*mat[1]) - (mat[7]*mat[0]) ) / det;
    result[8] = ( (mat[0]*mat[4]) - (mat[1]*mat[3]) ) / det;
    
    return result;    
}

unittest
{
    Matrix3x3 matrix = Matrix3x3( [ 1, 2, 3, 0, 1, 4, 5, 6, 0 ] );
    assert( matrix.inverse == [ -24, 18, 5, 20, -15, -4, -5, 4, 1 ] );
}

//Quaternion toQuaternion( ref const Matrix3x3 matrix )
auto ref toQuaternion( Matrix3x3 matrix )
{
    float s, w, x, y, z;
    float tr = matrix[0] + matrix[4] + matrix[8];

    if (tr > 0)
    { 
        s = sqrt(tr+1.0) * 2; // S=4*qw
        w = 0.25 * s;
        x = (matrix[5] - matrix[7]) / s;
        y = (matrix[6] - matrix[2]) / s; 
        z = (matrix[1] - matrix[3]) / s; 
    } 
    else if ( (matrix[0] > matrix[4]) & (matrix[0] > matrix[8]) ) 
    { 
        s = sqrt(1.0 + matrix[0] - matrix[4] - matrix[8]) * 2; // S=4*qx 
        w = (matrix[5] - matrix[7]) / s;
        x = 0.25 * s;
        y = (matrix[3] + matrix[1]) / s; 
        z = (matrix[6] + matrix[2]) / s; 
    } 
    else if (matrix[4] > matrix[8]) 
    { 
        s = sqrt(1.0 + matrix[4] - matrix[0] - matrix[8]) * 2; // S=4*qy
        w = (matrix[6] - matrix[2]) / s;
        x = (matrix[3] + matrix[1]) / s; 
        y = 0.25 * s;
        z = (matrix[7] + matrix[5]) / s; 
    } else { 
        s = sqrt(1.0 + matrix[8] - matrix[0] - matrix[4]) * 2; // S=4*qz
        w = (matrix[1] - matrix[3]) / s;
        x = (matrix[6] + matrix[2]) / s;
        y = (matrix[7] + matrix[5]) / s;
        z = 0.25 * s;
    }

/+
    if (tr > 0)
    { 
        s = sqrt(tr+1.0) * 2; // S=4*qw
        w = 0.25 * s;
        x = (matrix[7] - matrix[5]) / s;
        y = (matrix[2] - matrix[6]) / s; 
        z = (matrix[3] - matrix[1]) / s; 
    } 
    else if ( (matrix[0] > matrix[4]) & (matrix[0] > matrix[8])) 
    { 
        s = sqrt(1.0 + matrix[0] - matrix[4] - matrix[8]) * 2; // S=4*qx 
        w = (matrix[7] - matrix[5]) / s;
        x = 0.25 * s;
        y = (matrix[1] + matrix[3]) / s; 
        z = (matrix[2] + matrix[6]) / s; 
    } 
    else if (matrix[4] > matrix[8]) 
    { 
        s = sqrt(1.0 + matrix[4] - matrix[0] - matrix[8]) * 2; // S=4*qy
        w = (matrix[2] - matrix[6]) / s;
        x = (matrix[1] + matrix[3]) / s; 
        y = 0.25 * s;
        z = (matrix[5] + matrix[7]) / s; 
    } else { 
        s = sqrt(1.0 + matrix[8] - matrix[0] - matrix[4]) * 2; // S=4*qz
        w = (matrix[3] - matrix[1]) / s;
        x = (matrix[2] + matrix[6]) / s;
        y = (matrix[5] + matrix[7]) / s;
        z = 0.25 * s;
    }
+/ 
    auto q = Quaternion( w, x, y, z );
    if( q.w < 0.0 )
    {
        q.w *= -1;
        if( q.x != 0.0 ) q.x *= -1;
        if( q.y != 0.0 ) q.y *= -1;
        if( q.z != 0.0 ) q.z *= -1;
    }
    return q;
    //return Quaternion( w, x, y, z );
}

unittest
{
    Quaternion q = identity3x3.toQuaternion;
    assert( q == [ 1.0, 0.0, 0.0, 0.0 ] );
}


//Matrix3x3 makeMatrix3x3( ref const Vector3 axis, ref const float radian )
auto ref makeMatrix3x3( Vector3 axis, float radian )
{
    float c = cos( radian );
    float s = sin( radian );
    float t = 1.0 - c;
    
    float m00 = c + axis[0]*axis[0]*t;
    float m11 = c + axis[1]*axis[1]*t;
    float m22 = c + axis[2]*axis[2]*t;

    float tmp1;
    float tmp2;
    
    tmp1 = axis[0]*axis[1]*t;
    tmp2 = axis[2]*s;
    float m10 = tmp1 + tmp2;
    float m01 = tmp1 - tmp2;
    
    tmp1 = axis[0]*axis[2]*t;
    tmp2 = axis[1]*s;
    float m20 = tmp1 - tmp2;
    float m02 = tmp1 + tmp2;
    
    tmp1 = axis[1]*axis[2]*t;
    tmp2 = axis[0]*s;
    float m21 = tmp1 + tmp2;
    float m12 = tmp1 - tmp2;
    
    return Matrix3x3( [ m00, m10, m20, m01, m11, m21, m02, m12, m22 ] );

/+                 
    return [ m00, m01, m02, 0.0,
             m10, m11, m12, 0.0,
             m20, m21, m22, 0.0,
             0.0, 0.0, 0.0, 1.0 ];
+/
}

unittest
{

    Vector3 axis = Vector3( [ 1.0, 0.0, 0.0 ] );
    float angle = 90;
    float radian = angle * PI / 180;

    //assert( makeMatrix3x3( axis, radian ) == [ 1, 0, 0, 0, 0, 1, 0, -1, 0 ] );
}

/+ --------------------
   Matrix4x4
   -------------------- +/
struct Matrix4x4
{
    float[16] value;
    alias value this;
}

immutable Matrix4x4 identity4x4 = Matrix4x4( [ 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0 ] );

//Matrix3x3 getTransform( ref const Matrix4x4 mat )
auto ref getTransform( Matrix4x4 mat )
{
    return Matrix3x3( [ mat[0], mat[1], mat[2], mat[4], mat[5], mat[6], mat[8], mat[9], mat[10] ] );
}

//void setTransform( ref Matrix4x4 mat, ref const Matrix3x3 trans )
void setTransform( ref Matrix4x4 mat, Matrix3x3 trans )
{
    mat[0..3]  = trans[0..3].dup;
    mat[4..7]  = trans[3..6].dup;
    mat[8..11] = trans[6..9].dup;
}

unittest
{
    Matrix4x4 mat4 = identity4x4;
    Matrix3x3 mat3 = mat4.getTransform;
    assert( mat3 == identity3x3 );
    
    mat3 = [ 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 ];
    mat4.setTransform( mat3 );
                                  
    assert( mat4 == [ 0.0, 1.0, 2.0, 0.0, 
                      3.0, 4.0, 5.0, 0.0, 
                      6.0, 7.0, 8.0, 0.0,
                      0.0, 0.0, 0.0, 1.0 ] );    
    
}

//Vector3 getOrigin( ref const Matrix4x4 mat )
auto ref getOrigin( Matrix4x4 mat )
{
    return Vector3( [ mat[12], mat[13], mat[14] ] );
}

//void setOrigin( ref Matrix4x4 mat, ref const Vector3 origin )
void setOrigin( ref Matrix4x4 mat, Vector3 origin )
{
    mat[12] = origin[0];
    mat[13] = origin[1];
    mat[14] = origin[2];
}

unittest
{
    Matrix4x4 mat4 = identity4x4;
    Vector3   vec3 = mat4.getOrigin;
    assert( vec3 == [ 0.0, 0.0, 0.0 ] );
    
    vec3 = [ 0.0, 1.0, 2.0 ];
    mat4.setOrigin( vec3 );
                                  
    assert( mat4 == [ 1.0, 0.0, 0.0, 0.0, 
                      0.0, 1.0, 0.0, 0.0, 
                      0.0, 0.0, 1.0, 0.0,
                      0.0, 1.0, 2.0, 1.0 ] );    
    
}

//Matrix4x4 multMatrix( ref const Matrix4x4 l, ref const Matrix4x4 r )
auto ref multMatrix( Matrix4x4 l, Matrix4x4 r )
{
    Matrix4x4 result;
    result[0] = l[0]*r[0] + l[1]*r[4] + l[2]*r[8]  + l[3]*r[12];
    result[1] = l[0]*r[1] + l[1]*r[5] + l[2]*r[9]  + l[3]*r[13];
    result[2] = l[0]*r[2] + l[1]*r[6] + l[2]*r[10] + l[3]*r[14];
    result[3] = l[0]*r[3] + l[1]*r[7] + l[2]*r[11] + l[3]*r[15];
    
    result[4] = l[4]*r[0] + l[5]*r[4] + l[6]*r[8]  + l[7]*r[12];
    result[5] = l[4]*r[1] + l[5]*r[5] + l[6]*r[9]  + l[7]*r[13];
    result[6] = l[4]*r[2] + l[5]*r[6] + l[6]*r[10] + l[7]*r[14];
    result[7] = l[4]*r[3] + l[5]*r[7] + l[6]*r[11] + l[7]*r[15];
    
    result[8]  = l[8]*r[0] + l[9]*r[4] + l[10]*r[8]  + l[11]*r[12];
    result[9]  = l[8]*r[1] + l[9]*r[5] + l[10]*r[9]  + l[11]*r[13];
    result[10] = l[8]*r[2] + l[9]*r[6] + l[10]*r[10] + l[11]*r[14];
    result[11] = l[8]*r[3] + l[9]*r[7] + l[10]*r[11] + l[11]*r[15];
    
    result[12] = l[12]*r[0] + l[13]*r[4] + l[14]*r[8]  + l[15]*r[12];
    result[13] = l[12]*r[1] + l[13]*r[5] + l[14]*r[9]  + l[15]*r[13];
    result[14] = l[12]*r[2] + l[13]*r[6] + l[14]*r[10] + l[15]*r[14];
    result[15] = l[12]*r[3] + l[13]*r[7] + l[14]*r[11] + l[15]*r[15];
    //result[12] = l[12];
    //result[13] = l[13];
    //result[14] = l[14];
    //result[15] = l[15];
    
    return result;            
}


/+ --------------------
   Quaternion
   -------------------- +/
struct Quaternion
{
    float w, x, y, z;

    float[4] value()
    {
        return [ w, x, y, z ];
    }
    alias value this;
}

//Matrix3x3 toMatrix3x3( const Quaternion q )
auto ref toMatrix3x3( Quaternion q )
{
    float sqw = q.w ^^ 2;
    float sqx = q.x ^^ 2;
    float sqy = q.y ^^ 2;
    float sqz = q.z ^^ 2;

    Matrix3x3 result;

    result[0]  = (  sqx - sqy - sqz + sqw );
    result[4]  = ( -sqx + sqy - sqz + sqw );
    result[8] = ( -sqx - sqy + sqz + sqw );

    float tmp1;
    float tmp2;

    tmp1 = q.x * q.y;
    tmp2 = q.z * q.w;
    result[1] = ( tmp1 + tmp2 ) * 2.0;
    result[3] = ( tmp1 - tmp2 ) * 2.0;

    tmp1 = q.x * q.z;
    tmp2 = q.y * q.w;
    result[2] = ( tmp1 - tmp2 ) * 2.0;
    result[6] = ( tmp1 + tmp2 ) * 2.0;

    tmp1 = q.y * q.z;
    tmp2 = q.x * q.w;
    result[5] = ( tmp1 + tmp2 ) * 2.0;
    result[7] = ( tmp1 - tmp2 ) * 2.0;

    return result;
}

unittest
{
    Vector3 axis = Vector3( [ 1.0, 0.0, 0.0 ] );
    float radian = 90.0 * PI / 180;

    Matrix3x3 matrix1 = makeQuaternion( axis, radian ).toMatrix3x3();
    //assert( matrix1 == [ 1, 0, 0, 0, 0, 1, 0, -1, 0 ] );
    
    Matrix3x3 matrix2 = makeMatrix3x3( axis, radian );
    //assert( matrix2 == [ 1, 0, 0, 0, 0, 1, 0, -1, 0 ] );
    
    //assert( matrix1 == matrix2 );
}

void normalize( ref Quaternion q )
{
    //float len = sqrt( q.w^^2 + q.x^^2 + q.y^^2 + q.z^^2 );
    float len = sqrt( (q.w * q.w) + (q.x * q.x) + (q.y * q.y) + (q.z * q.z) );
    if( len > 0.0 )
    {
        q.w /= len;
        q.x /= len;
        q.y /= len;
        q.z /= len;
    }
}

//Quaternion multQuaternion( ref const Quaternion l, ref const Quaternion r )
auto ref multQuaternion( Quaternion l, Quaternion r )
{
    return Quaternion( (l.w * r.w) - (l.x * r.x) - (l.y * r.y) - (l.z * r.z),
                       (l.w * r.x) + (l.x * r.w) + (l.y * r.z) - (l.z * r.y),
                       (l.w * r.y) - (l.x * r.z) + (l.y * r.w) + (l.z * r.x),
                       (l.w * r.z) + (l.x * r.y) - (l.y * r.x) + (l.z * r.w) );
}

//Quaternion Slerp( ref const Quaternion s, ref const Quaternion e, ref const float t )
auto ref Slerp( Quaternion s, Quaternion e, float t )
{
    float qr = (s.w * e.w) + (s.x * e.x) + (s.y * e.y) + (s.z * e.z);
    float ss = 1.0 - (qr * qr);

    Quaternion q;

    if( ss == 0.0 )
    {
        q.w = s.w;
        q.x = s.x;
        q.y = s.y;
        q.z = s.z;
    }
    else
    {
        float sp = sqrt( ss );
        float ph = acos( qr );
        float pt = ph * t;
        float t1 = sin( pt ) / sp;
        float t0 = sin( ph - pt ) / sp;

        q.w = ( s.w * t0 ) + ( e.w * t1 );
        q.x = ( s.x * t0 ) + ( e.x * t1 );
        q.y = ( s.y * t0 ) + ( e.y * t1 );
        q.z = ( s.z * t0 ) + ( e.z * t1 );
    }

    return q;
}

//from w x y z
//Quaternion makeQuaternion( ref const float w, ref const float x, ref const float y, ref const float z )
auto ref makeQuaternion( float w, float x, float y, float z )
{
    return Quaternion( w, x, y, z );
}

unittest
{
    float w = 0.0;
    float x = 1.0;
    float y = 2.0;
    float z = 3.0;

    assert( makeQuaternion( w, x, y, z ) == [ 0.0, 1.0, 2.0, 3.0 ] );
}

//axis-angle
//Quaternion makeQuaternion( ref const Vector3 axis, ref const float radian )
auto ref makeQuaternion( Vector3 axis, float radian )
{
    float c = cos( 0.5 * radian );
    float s = sin( 0.5 * radian );
    Quaternion q =  Quaternion( c, axis[0] * s, axis[1] * s, axis[2] * s );
    //if( abs(q.w) == 0.0 ) q.w = 0.0;
    //if( abs(q.x) == 0.0 ) q.x = 0.0;
    //if( abs(q.y) == 0.0 ) q.y = 0.0;
    //if( abs(q.z) == 0.0 ) q.z = 0.0;

    return q;
}

unittest
{
    float[4] fetch( Quaternion q )
    {
        int w = (q.w * 1000000).to!int;
        int x = (q.x * 1000000).to!int;
        int y = (q.y * 1000000).to!int;
        int z = (q.z * 1000000).to!int;
        return [ w, x, y, z ];
        //return [ w.to!float / 1000000, x.to!float / 1000000, y.to!float / 1000000, z.to!float / 1000000 ];
    }

    Vector3 axis = Vector3( [ 1.0, 0.0, 0.0 ] );
    float radian = 90.0 * PI / 180;

    assert( fetch( makeQuaternion( axis, radian ) ) ==  [ 707106, 707106, 0.0, 0.0 ] );
    
    axis = Vector3( [-1, 0, 0] );
    radian = 1.107149;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 850650, -525731, 0, 0] );
    axis = Vector3( [-1, 0, 0] );
    radian = 0.231824;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 993289, -115652, 0, 0] );
    axis = Vector3( [1, 0, 0] );
    radian = 0.293764;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 989232, 146354, 0, 0] );
    axis = Vector3( [-1, 0, 0] );
    radian = 0.146882;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 997304, -73375, 0, 0] );
    axis = Vector3( [1, 0, 0] );
    radian = 0.202473;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 994879, 101063, 0, 0] );
    axis = Vector3( [-1, 0, 0] );
    radian = 0.101237;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 998719, -50596, 0, 0] );
    axis = Vector3( [1, 0, -0] );
    radian = 0.146400;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 997322, 73134, 0, 0] );
    axis = Vector3( [-1, 0, 0] );
    radian = 0.073199;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 999330, -36591, 0, 0] );
    axis = Vector3( [1, 0, 0] );
    radian = 0.108823;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 998520, 54384, 0, 0] );
    axis = Vector3( [-1, 0, 0] );
    radian = 0.054412;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 999629, -27202, 0, 0] );
    
    axis = Vector3( [0.00197151, 0.999423, -0.0339128] );
    radian = 1.717996;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 653196, 1492, 756751, -25678] );
    axis = Vector3( [-0.409685, 0.0734125, -0.909268] );
    radian = 0.625945;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 951422, -126137, 22602, -279952] );
    axis = Vector3( [0.0533615, 0.998104, -0.0306755] );
    radian = 1.710131;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 656169, 40267, 753183, -23148] );
    axis = Vector3( [-0.422688, 0.122333, -0.897981] );
    radian = 0.641695;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 948968, -133303, 38580, -283197] );
    axis = Vector3( [0.0872139, 0.994162, -0.0635181] );
    radian = 1.740357;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 644690, 66670, 759981, -48556] );
    axis = Vector3( [-0.451576, 0.034284, -0.891574] );
    radian = 0.610622;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 953753, -135739, 10305, -267998] );
    axis = Vector3( [0.1406, 0.975411, -0.169721] );
    radian = 1.664480;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 673221, 103965, 721259, -125498] );
    axis = Vector3( [-0.526701, -0.0307511, -0.849494] );
    radian = 0.537840;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 964058, -139939, -8170, -225702] );
    axis = Vector3( [0.141462, 0.950569, -0.276417] );
    radian = 1.474380;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 740360, 95092, 638982, -185810] );
    axis = Vector3( [-0.483663, -0.0252773, -0.874889] );
    radian = 0.451451;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 974631, -108250, -5657, -195811] );
    axis = Vector3( [0.176079, 0.861992, -0.47536] );
    radian = 1.334071;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 785659, 108932, 533279, -294086] );
    axis = Vector3( [-0.344767, -0.0785672, -0.935395] );
    radian = 0.392689;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 980786, -67259, -15327, -182481] );
    axis = Vector3( [-0.0104576, 0.777645, -0.628616] );
    radian = 1.284738;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 800678, -6265, 465882, -376600] );
    axis = Vector3( [0.175255, -0.471985, -0.864012] );
    radian = 0.524441;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 965816, 45430, -122350, -223974] );
    axis = Vector3( [0.876473, 0.160413, -0.453942] );
    radian = 1.058109;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 863284, 442371, 80963, -229112] );
    axis = Vector3( [0.354739, -0.881631, -0.311268] );
    radian = 1.669215;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 671468, 262873, -653317, -230659] );
    axis = Vector3( [0.802206, 0.132464, -0.582168] );
    radian = 0.775894;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 925687, 303465, 50109, -220227] );
    axis = Vector3( [0.821199, -0.235081, -0.519971] );
    radian = 1.429530;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 755247, 538246, -154081, -340809] );
    axis = Vector3( [0.471859, 0.359949, -0.804851] );
    radian = 0.635698;
    assert( fetch( makeQuaternion( axis, radian ) ) == [ 949909, 147467, 112492, -251535] );

}

//void toAxisAngle( ref const Quaternion q, out float[3] axis, out float angle )
void toAxisAngle( Quaternion q, out float[3] axis, out float angle )
{
    if( q.w > 1.0 ) q.normalize();
    angle = acos( q.w ) * 2.0 * 180 / PI;

    float s = sqrt( 1 - ( q.w * q.w ) );
    if( s < 0.001 )
    {
        axis[0] = q.x;
        axis[1] = q.y;
        axis[2] = q.z;
    }
    else
    {
        axis[0] = q.x / s;
        axis[1] = q.y / s;
        axis[2] = q.z / s;
    }
}

//yaw pitch roll
//Euler
//Quaternion makeQuaternion( ref const Vector3 euler ) {
auto ref makeQuaternion( Vector3 euler ) {
    return makeQuaternion( euler[0], euler[1], euler[2] );
}

//Quaternion makeQuaternion( ref const float yaw, ref const float pitch, ref const float roll )
auto ref makeQuaternion( float yaw, float pitch, float roll ) 
{

    // Assuming the angles are in radians.
    float c1 = cos(yaw/2);
    float s1 = sin(yaw/2);
    float c2 = cos(pitch/2);
    float s2 = sin(pitch/2);
    float c3 = cos(roll/2);
    float s3 = sin(roll/2);
    float c1c2 = c1*c2;
    float s1s2 = s1*s2;
    float w =c1c2*c3 - s1s2*s3;
      float x =c1c2*s3 + s1s2*c3;
    float y =s1*c2*c3 + c1*s2*s3;
    float z =c1*s2*c3 - s1*c2*s3;
    
    return Quaternion( w, x, y, z );
}

//Vector3 toEuler( Quaternion q )
auto ref toEuler( Quaternion q )
{
    Vector3 result;
    
    float test = q.x*q.y + q.z*q.w;
    if (test > 0.499) { // singularity at north pole
        result[0] = 2 * atan2(q.x,q.w);
        result[1] = PI/2;
        result[2] = 0;
        return result;
    }
    if (test < -0.499) { // singularity at south pole
        result[0] = -2 * atan2(q.x,q.w);
        result[1] = -PI/2;
        result[2] = 0;
        return result;
    }

    float sqx = q.x*q.x;
    float sqy = q.y*q.y;
    float sqz = q.z*q.z;
    result[0] = atan2(2*q.y*q.w-2*q.x*q.z , 1 - 2*sqy - 2*sqz);
    result[1] = asin(2*test);
    result[2] = atan2(2*q.x*q.w-2*q.y*q.z , 1 - 2*sqx - 2*sqz);

    return result;
}

unittest
{
    float w, x, y, z;
    w = x = 0.5;
    y = z = 0.5;
    
    Quaternion q = makeQuaternion( w, x, y, z );
    
    //float[3] euler = q.toEuler();
    //writeln( euler[0] * 180 / PI );
    //assert( q.toEuler == [ 0.0, 90.0, 0.0 ] );
}
