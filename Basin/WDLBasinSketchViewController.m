//
//  WDLBasinSketchViewController.m
//  Basin
//
//  Created by William Lindmeier on 2/19/13.
//  Copyright (c) 2013 wdlindmeier. All rights reserved.
//

#import "WDLBasinSketchViewController.h"
#import "NOCShaderProgram.h"
#import "NOCMover3D.h"
#import "NOCSceneBox.h"
#import "station_restore_geo_data.h"
#import <GLKit/GLKit.h>

@interface WDLBasinSketchViewController ()
{
    GLKTextureInfo *_nodeTexture;
    NSMutableArray *_movers;
    NOCSceneBox *_sceneBox;
    NSMutableSet *_currentTouches;
    GLKMatrix4 _matScene;
    
    float _xRotationRate;
    float _yRotationRate;
    float _yRotation;
    float _xRotation;
    float _depthZoom;
    float _prevPinchDistance;
    
}

@end

@implementation WDLBasinSketchViewController

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

}

static NSString * NOCShaderNameMovers3DMover = @"Mover";
static NSString * NOCShaderNameSceneBox = @"SimpleLine";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

- (void)setup
{
    
    self.view.multipleTouchEnabled = YES;
    
    _currentTouches = [NSMutableSet setWithCapacity:10];
    _yRotationRate = 0.0f;
    _xRotationRate = 0.0f;
    _yRotation = 0.0f;
    _xRotation = 0.0f;    
    _depthZoom = -4.0f;

    // Load the mover texture.
    UIImage *moverTexImage = [UIImage imageNamed:@"mover"];
    NSError *texError = nil;
    _nodeTexture = [GLKTextureLoader textureWithCGImage:moverTexImage.CGImage
                                                options:nil
                                                  error:&texError];
    if(texError){
        NSLog(@"ERROR: Could not load the texture: %@", texError);
    }
    
    // Setup the shaders
    NOCShaderProgram *shaderMovers = [[NOCShaderProgram alloc] initWithName:NOCShaderNameMovers3DMover];
    shaderMovers.attributes = @{@"position" : @(GLKVertexAttribPosition),
                                @"texCoord" : @(GLKVertexAttribTexCoord0)};
    shaderMovers.uniformNames = @[ UniformMVProjectionMatrix, UniformMoverTexture ];
    
    NOCShaderProgram *shaderScene = [[NOCShaderProgram alloc] initWithName:NOCShaderNameSceneBox];
    shaderScene.attributes = @{ @"position" : @(GLKVertexAttribPosition) };
    shaderScene.uniformNames = @[ UniformMVProjectionMatrix ];
    
    self.shaders = @{NOCShaderNameMovers3DMover : shaderMovers,
                     NOCShaderNameSceneBox : shaderScene};
    

    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;
    
    _sceneBox = [[NOCSceneBox alloc] initWithAspect:aspect];
    
    
    _movers = [NSMutableArray arrayWithCapacity:1000];

    float moverDimension = 0.02;
    for(int i=0;i<NumStations;i++){
        GLKVector3 sizeMover = GLKVector3Make(moverDimension, moverDimension, moverDimension);        
        GLKVector3 positionMover = GLKVector3Make(StationGeometry[i*3] * 2 - 1,
                                                  StationGeometry[i*3+1] * -2 + 1,
                                                  StationGeometry[i*3+2] * 2 - 1);
        NOCMover3D *mover = [[NOCMover3D alloc] initWithSize:sizeMover
                                                    position:positionMover
                                                        mass:1.0];
        [_movers addObject:mover];
    }
    
}

- (void)resize
{
    [super resize];
    
    [self clear];
    // Create the box vertecies
    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;
    [_sceneBox resizeWithAspect:aspect];
    
}

- (void)update
{
    [super update];
    [self updateOrientation];
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, _depthZoom);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, GLKMathDegreesToRadians(_xRotation), 1.0f, 0.0f, 0.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, GLKMathDegreesToRadians(_yRotation), 0.0f, 1.0f, 0.0f);
    _matScene = baseModelViewMatrix;
}

- (void)updateOrientation
{
    if([_currentTouches count] < 1){
        float rotationDecayRate = 0.99;
        // Decay the rotation
        _yRotationRate *= rotationDecayRate;
        _xRotationRate *= rotationDecayRate;
    }
    _yRotation += _yRotationRate;

    _xRotation += _xRotationRate;

}

- (void)draw
{
    
    [self clear];

    GLKMatrix4 matScene = GLKMatrix4Multiply(_projectionMatrix3D, _matScene);

    float zMulti = self.sliderDepth.value;
    matScene = GLKMatrix4Multiply(matScene, GLKMatrix4MakeScale(1, 1, zMulti));

    NSNumber *projMatLoc = nil;
    
    // Draw the scene box
    NOCShaderProgram *shaderScene = self.shaders[NOCShaderNameSceneBox];
    [shaderScene use];
    // Create the Model View Projection matrix for the shader
    projMatLoc = shaderScene.uniformLocations[UniformMVProjectionMatrix];
    // Pass mvp into shader
    glUniformMatrix4fv([projMatLoc intValue], 1, 0, matScene.m);
    [_sceneBox render];
    
    // Draw the movers

    NOCShaderProgram *shaderMovers = self.shaders[NOCShaderNameMovers3DMover];
    [shaderMovers use];
    
    // Enable alpha blending for the transparent png
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _nodeTexture.name);
    
    // Attach the texture to the shader
    NSNumber *samplerLoc = shaderMovers.uniformLocations[UniformMoverTexture];
    glUniform1i([samplerLoc intValue], 0);
    
    // Create the Model View Projection matrix for the shader
    projMatLoc = shaderMovers.uniformLocations[UniformMVProjectionMatrix];
    
    GLKMatrix4 inverseSceneMat = GLKMatrix4Identity;
    inverseSceneMat = GLKMatrix4Rotate(inverseSceneMat, GLKMathDegreesToRadians(_xRotation*-1), 1.0f, 0.0f, 0.0f);
    inverseSceneMat = GLKMatrix4Rotate(inverseSceneMat, GLKMathDegreesToRadians(_yRotation*-1), 0.0f, 1.0f, 0.0f);
    
    // Render each mover
    for(NOCMover3D *mover in _movers){
        
        // Get the model matrix
        GLKMatrix4 modelMat = [mover modelMatrix];
        
        // TODO:
        // Maultiply by the inverse of the scene mat.
        // Does this billbaord the texture?
        modelMat = GLKMatrix4Multiply(modelMat, inverseSceneMat);
        
        // Multiply by the projection matrix
        GLKMatrix4 mvProjMat = GLKMatrix4Multiply(matScene, modelMat);
        
        // Pass mvp into shader
        glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);
        
        [mover render];
        
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_BLEND);
    glDisable(GL_TEXTURE_2D);
    
}

- (void)teardown
{
    //..
}

#pragma mark - Touch

- (float)distanceBetweenTouches:(NSArray *)touches
{
    if([touches count] > 1){
        UITouch *t1 = [touches objectAtIndex:0];
        UITouch *t2 = [touches objectAtIndex:1];
        CGPoint t1pt = [t1 locationInView:t1.view];
        CGPoint t2pt = [t2 locationInView:t2.view];
        float xDelta = t1pt.x - t2pt.x;
        float yDelta = t1pt.y - t2pt.y;
        return sqrt((xDelta*xDelta) + (yDelta*yDelta));
    }
    return 0.0;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [_currentTouches addObjectsFromArray:[touches allObjects]];
    
    _yRotationRate = 0.0;
    _xRotationRate = 0.0;
    
    if([_currentTouches count] == 2){
        _prevPinchDistance = [self distanceBetweenTouches:[_currentTouches allObjects]];
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if([_currentTouches count] == 1){
        
        for( UITouch *touch in (NSSet *)touches ) {
            CGPoint pt = [touch locationInView:touch.view];
            CGPoint prevPt = [touch previousLocationInView:touch.view];
            
            float xDelta = pt.x - prevPt.x;
            float yDelta = pt.y - prevPt.y;
            
            // IMPORTANT NOTE:
            // The xDelta affects the yRotation rate
            // and the yDelta affects the xRotation rate
            
            float rotationDampener = 0.15;
            _yRotationRate = (xDelta * rotationDampener);
            _xRotationRate = (yDelta * rotationDampener);
            
        }
        
    }else if([_currentTouches count] == 2){
        
        float pinchDistance = [self distanceBetweenTouches:[_currentTouches allObjects]];
        float pinchDelta = pinchDistance - _prevPinchDistance;
        _depthZoom += pinchDelta * 0.005;
        _prevPinchDistance = pinchDistance;
        
    }
}

- (void)endPinch
{
    _prevPinchDistance = 0.0;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    //...
    if([_currentTouches count] == 2){
        [self endPinch];
    }
    for(id t in touches)
        [_currentTouches removeObject:t];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if([_currentTouches count] == 2){
        [self endPinch];
    }
    for(id t in touches)
        [_currentTouches removeObject:t];
    
}

@end
