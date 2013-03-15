attribute vec3 position;

varying vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    gl_Position = modelViewProjectionMatrix * vec4(position, 1.0);
    colorVarying = vec4(position.z, position.z, position.z, 1.0);
}

