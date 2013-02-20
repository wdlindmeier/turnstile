//
//  NOCMover3D.m
//  Nature of Code
//
//  Created by William Lindmeier on 2/13/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "NOCMover3D.h"
#import "NOCGeometryHelpers.h"

// A flat square.
GLfloat mover3DBillboardVertexData[12] =
{
    -0.5f, -0.5f, 0.0f,
    0.5f, -0.5f, 0.0f,
    -0.5f, 0.5f, 0.0f,
    0.5f, 0.5f, 0.0f,
    
};

// 2D Texture coords for billboard rendering.
GLfloat mover3DTexCoords[8] =
{
    0.f, 1.f,
    1.f, 1.f,
    0.f, 0.f,
    1.f, 0.f
};

@implementation NOCMover3D

- (id)initWithSize:(GLKVector3)size position:(GLKVector3)position mass:(float)mass
{
    self = [super initWithSize:size position:position];
    if(self){
        self.velocity = GLKVector3Zero;
        self.acceleration = GLKVector3Zero;
        self.maxVelocity = 5.0f;
        self.mass = mass;
    }
    return self;
}

#pragma mark - Force

- (void)applyForce:(GLKVector3)vecForce
{
    self.acceleration = GLKVector3Add(self.acceleration, vecForce);
}

- (GLKVector3)forceOnPositionedMass:(id<NOCPositionedMass3D>)positionedMass
{
    GLKVector3 vecDir = GLKVector3Subtract(positionedMass.position, self.position);
    float magnitude = GLKVector3Length(vecDir);
    vecDir = GLKVector3Normalize(vecDir);
    float forceMagnitude = (Gravity * self.mass * positionedMass.mass) / (magnitude * magnitude);
    GLKVector3 vecForce = GLKVector3MultiplyScalar(vecDir, forceMagnitude);
    return vecForce;
}

#pragma mark - Update

- (void)step
{
    // Add accel to velocity
    self.velocity = GLKVector3Add(self.velocity, self.acceleration);
    
    // Limit the velocity
    self.velocity = GLKVector3Limit(self.velocity, self.maxVelocity);

    // Add velocity to location
    self.position = GLKVector3Add(self.position, self.velocity);    

    // Reset the acceleration
    self.acceleration = GLKVector3Zero;
}

- (void)stepInBox:(NOCBox3D)box shouldWrap:(BOOL)shouldWrap
{
    [self step];
    
    float x = self.position.x;
    float y = self.position.y;
    float z = self.position.z;

    float minX = box.origin.x;
    float maxX = (box.origin.x + box.size.x);
    float minY = box.origin.y;
    float maxY = (box.origin.y + box.size.y);
    float minZ = box.origin.z;
    float maxZ = (box.origin.z + box.size.z);
    
    if(shouldWrap){
        // Wrap the mover around the rect
        if(x < minX) x = maxX + (x - minX);
        else if(x > maxX) x = minX + (x - maxX);
        
        if(y < minY) y = maxY + (y - minY);
        else if(y > maxY) y = minY + (y - maxY);

        if(z < minZ) z = maxZ + (z - minZ);
        else if(z > maxZ) z = minZ + (z - maxZ);
    }else{
        // Constrain
        // Dont let the walker move outside of the rect.
        x = CONSTRAIN(x, minX, maxX);
        y = CONSTRAIN(y, minY, maxY);
        z = CONSTRAIN(z, minZ, maxZ);
    }
    
    self.position = GLKVector3Make(x, y, z);
}

#pragma mark - Draw

- (void)render
{    
    // Draw a colored square
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);

    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &mover3DBillboardVertexData);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, &mover3DTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

}

@end