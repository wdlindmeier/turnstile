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
#import "Edgy.h"
#import "DelaunayTriangulation+NOCHelpers.h"

static inline float zPosForXY(float px, float py)
{
    for(int j=0;j<NumStations;j++){
        float x = StationGeometry[j*3] * 2 - 1;
        float y = StationGeometry[j*3+1] * -2 + 1;
        float z = StationGeometry[j*3+2];
//        float x = StationGeometry[i*3]
//        float y = StationGeometry[i*3+1]

        if(px == x & py == y){
            return z;
            break;
        }
    }
    return -1;
}

@interface WDLBasinSketchViewController ()
{
    DelaunayTriangulation *_triangulation;
    NSMutableArray *_movers;
    NOCSceneBox *_sceneBox;
    NSMutableSet *_currentTouches;
    GLKMatrix4 _matScene;
    GLfloat *_trianglePoints;
    int _numTrianglePoints;
    
    float _xRotationRate;
    float _yRotationRate;
    float _yRotation;
    float _xRotation;
    float _depthZoom;
    float _prevPinchDistance;
    BOOL _didExportOBJ;

}

@end

@implementation WDLBasinSketchViewController

#pragma mark - Draw Loop

- (void)clear
{
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

}

static NSString * NOCShaderNameBasin = @"Basin";
static NSString * NOCShaderNameSceneBox = @"SimpleLine";
static NSString * UniformMVProjectionMatrix = @"modelViewProjectionMatrix";
static NSString * UniformMoverTexture = @"texture";

- (void)setup
{
    _didExportOBJ = YES;//NO;
    
    self.view.multipleTouchEnabled = YES;
    
    _currentTouches = [NSMutableSet setWithCapacity:10];
    _yRotationRate = 0.0f;
    _xRotationRate = 0.0f;
    _yRotation = 0.0f;
    _xRotation = 0.0f;    
    _depthZoom = -4.0f;


    // Setup the shaders
    NOCShaderProgram *shaderMovers = [[NOCShaderProgram alloc] initWithName:NOCShaderNameBasin];
    shaderMovers.attributes = @{@"position" : @(GLKVertexAttribPosition)};
    shaderMovers.uniformNames = @[ UniformMVProjectionMatrix ];
    
    NOCShaderProgram *shaderScene = [[NOCShaderProgram alloc] initWithName:NOCShaderNameSceneBox];
    shaderScene.attributes = @{ @"position" : @(GLKVertexAttribPosition) };
    shaderScene.uniformNames = @[ UniformMVProjectionMatrix ];
    
    self.shaders = @{NOCShaderNameBasin : shaderMovers,
                     NOCShaderNameSceneBox : shaderScene};
    

    CGSize sizeView = self.view.frame.size;
    float aspect = sizeView.width / sizeView.height;
    
    _sceneBox = [[NOCSceneBox alloc] initWithAspect:aspect];
    
    float _viewAspect = sizeView.width / sizeView.height;
    _triangulation = [DelaunayTriangulation triangulationWithGLSize:CGSizeMake(2.0, 2.0/_viewAspect)];
    for(int i=0;i<NumStations;i++){
        float x = StationGeometry[i*3] * 2 - 1;
        float y = StationGeometry[i*3+1] * -2 + 1;
        DelaunayPoint *newPoint = [DelaunayPoint pointAtX:x
                                                     andY:y];
        [_triangulation addPoint:newPoint withColor:nil];
    }
    
    _numTrianglePoints = _triangulation.triangles.count * 4;

    _trianglePoints = malloc(sizeof(GLfloat) * _numTrianglePoints * 3);
    
    int idxPoint = 0;
    for (DelaunayTriangle *triangle in _triangulation.triangles)
    {
        DelaunayPoint *prevPoint = triangle.startPoint;
        int edgeCount = triangle.edges.count;
        for(int i=0;i<edgeCount;i++)
        {
            DelaunayEdge *edge = triangle.edges[i];
            DelaunayPoint *p2 = [edge otherPoint:prevPoint];
            _trianglePoints[idxPoint+(i*3)+0] = p2.x;
            _trianglePoints[idxPoint+(i*3)+1] = p2.y;
            _trianglePoints[idxPoint+(i*3)+2] = zPosForXY(p2.x,p2.y);
            
            prevPoint = p2;
        }
        
        // Close
        _trianglePoints[idxPoint+(edgeCount*3)+0] = prevPoint.x;
        _trianglePoints[idxPoint+(edgeCount*3)+1] = prevPoint.y;
        _trianglePoints[idxPoint+(edgeCount*3)+2] = zPosForXY(prevPoint.x,prevPoint.y);
        
        idxPoint+=edgeCount+1;
        
    }
    
    NSLog(@"idxPoint: %i numPoints: %i", idxPoint, _numTrianglePoints);

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

int idxForXYX(float x, float y, float z, NSMutableArray *inVerts)
{
    NSString *vtx = [NSString stringWithFormat:@"%f %f %f", x, y, z];
    int idx = [inVerts indexOfObject:vtx];
    if(idx == NSNotFound){
        [inVerts addObject:vtx];
        idx = inVerts.count - 1;
    }
    return idx + 1; // indexes start with 1
}

- (void)draw
{
    
    [self clear];

    GLKMatrix4 matScene = GLKMatrix4Multiply(_projectionMatrix3D, _matScene);

    float zMulti = 0.0f;//self.sliderDepth.value;
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
    
    // Draw the points
    NOCShaderProgram *shaderMovers = self.shaders[NOCShaderNameBasin];
    [shaderMovers use];
    
    // Create the Model View Projection matrix for the shader
    projMatLoc = shaderMovers.uniformLocations[UniformMVProjectionMatrix];
    // Pass mvp into shader
    glUniformMatrix4fv([projMatLoc intValue], 1, 0, matScene.m);


    glEnable(GL_DEPTH_TEST);
    
    NSMutableArray *verts = nil;
    NSMutableArray *faces = nil;
    
    if(!_didExportOBJ){
        verts = [NSMutableArray arrayWithCapacity:_numTrianglePoints];
        faces = [NSMutableArray arrayWithCapacity:_numTrianglePoints];
    }
    
    for (DelaunayTriangle *triangle in _triangulation.triangles)
    {
        int edgeCount = triangle.edges.count;
        int numPoints = edgeCount + 1;
        GLfloat trianglePoints[numPoints*3];
        
        DelaunayPoint *prevPoint = triangle.startPoint;
        
        NSMutableArray *indexes = [NSMutableArray array];
        
        for(int i=0;i<edgeCount;i++)
        {
            DelaunayEdge *edge = triangle.edges[i];
            DelaunayPoint *p2 = [edge otherPoint:prevPoint];
            float x = p2.x;
            float y = p2.y;
            float z = zPosForXY(p2.x,p2.y);
            trianglePoints[i*3+0] = x;
            trianglePoints[i*3+1] = y;
            trianglePoints[i*3+2] = z;
            
            if(!_didExportOBJ){
                [indexes addObject:@(idxForXYX(x,y,z,verts))];
            }
            
            prevPoint = p2;
            
        }
        
        // Close
        float x = prevPoint.x;
        float y = prevPoint.y;
        float z = zPosForXY(prevPoint.x,prevPoint.y);
        trianglePoints[edgeCount*3+0] = x;
        trianglePoints[edgeCount*3+1] = y;
        trianglePoints[edgeCount*3+2] = z;
        
        // I dont think we need this

        if(!_didExportOBJ){
            //[indexes addObject:@(idxForXYX(x,y,z,verts))];
        }

        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, &trianglePoints);
        
        int numCoords = sizeof(trianglePoints) / sizeof(GLfloat) / 3;
        
        glDrawArrays(GL_TRIANGLES, 0, numCoords);
        
        if(!_didExportOBJ){
            // Add the face to the list
            [faces addObject:[indexes componentsJoinedByString:@" "]];
        }
    }
    
    if(!_didExportOBJ){
        // Print out the obj
        NSLog(@"\nv %@", [verts componentsJoinedByString:@"\nv "]);
        NSLog(@"\nf %@", [faces componentsJoinedByString:@"\nf "]);
    }
    
    _didExportOBJ = YES;
    
    /*
    // Bind the texture
    glEnable(GL_TEXTURE_2D);
    glActiveTexture(0);
    glBindTexture(GL_TEXTURE_2D, _nodeTexture.name);
    
    // Attach the texture to the shader
    NSNumber *samplerLoc = shaderMovers.uniformLocations[UniformMoverTexture];
    glUniform1i([samplerLoc intValue], 0);
    
    // Create the Model View Projection matrix for the shader
    projMatLoc = shaderMovers.uniformLocations[UniformMVProjectionMatrix];
    
    // Render each mover
    for(NOCMover3D *mover in _movers){
        
        // Get the model matrix
        GLKMatrix4 modelMat = [mover modelMatrix];
        
        // TODO:
        // Maultiply by the inverse of the scene mat.
        // Does this billbaord the texture?
        // modelMat = GLKMatrix4Multiply(modelMat, inverseSceneMat);
     
        // Multiply by the projection matrix
        GLKMatrix4 mvProjMat = GLKMatrix4Multiply(matScene, modelMat);
        
        // Pass mvp into shader
        glUniformMatrix4fv([projMatLoc intValue], 1, 0, mvProjMat.m);
        
        [mover render];
        
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisable(GL_BLEND);
    glDisable(GL_TEXTURE_2D);
    */
}

- (void)teardown
{
    //..
    free(_trianglePoints);
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
