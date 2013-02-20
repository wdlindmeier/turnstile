//
//  Shader.fsh
//  Basin
//
//  Created by William Lindmeier on 2/19/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
