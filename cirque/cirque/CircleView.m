//
//  CircleView.m
//  cirque
//
//  Created by Ivan Milles on 03/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

#import "CircleView.h"
#import "ES2Program.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "cirque-Swift.h"

@interface CircleView ()
@property (strong) ES2Program* circleShader;
@property GLuint vertexArray;
@property GLuint vertexBuffer;
@end

@implementation CircleView

-(id) init {
	if (self = [super init]) {

		_circleShader = [[ES2Program alloc] initWithVertexShader:@"Shader.vsh" fragmentShader:@"Shader.fsh" debugName:@"Circle shader"];
		glGenVertexArraysOES(1, &_vertexArray);
		assert(glGetError() == GL_NO_ERROR && "Setup circle vertex data failed");
		glGenBuffers(1, &_vertexBuffer);
		assert(glGetError() == GL_NO_ERROR && "Setup circle vertex data failed");
	}
	return self;
}

-(void) render:(Circle *)model {
	[_circleShader use];
	
	GLKMatrix4 mvpMatrix = GLKMatrix4MakeOrtho(0, _viewSize.width, 0, _viewSize.height,  10, -10);
	mvpMatrix = GLKMatrix4Translate(mvpMatrix, _viewSize.width/2, _viewSize.height/2, 0);
	[_circleShader setUniform: @"modelViewProjectionMatrix" matrixValue: mvpMatrix];
	
	// $ Crazy to do this per-frame. Memory-map a buffer?
	NSArray* nsSegments = model.segments;
	int nSegments = (int) nsSegments.count;
	int nVertices = nSegments * 2;
	int nCoords = nVertices * 2;
	int circleIndices[nVertices];
	float coords[nCoords];

	int vertexIndex = 0;
	int coordIndex = 0;
	float thickness = 5.0f;
	for (Segment *s in nsSegments) {
		float a = s.angle;
		float ir = s.radius - (thickness / 2.0f);
		float or = s.radius + (thickness / 2.0f);
		// Add the two vertices
		circleIndices[vertexIndex] = vertexIndex;		vertexIndex++;
		coords[coordIndex] = cos(a) * ir;						coordIndex++;
		coords[coordIndex] = sin(a) * ir;						coordIndex++;
		
		circleIndices[vertexIndex] = vertexIndex;		vertexIndex++;
		coords[coordIndex] = cos(a) * or;						coordIndex++;
		coords[coordIndex] = sin(a) * or;						coordIndex++;
	}
	
	glBindVertexArrayOES(_vertexArray);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, nCoords * sizeof(float), coords, GL_DYNAMIC_DRAW);
	
	glEnableVertexAttribArray([_circleShader getAttribute:@"position"]);
	glVertexAttribPointer([_circleShader getAttribute:@"position"], 2, GL_FLOAT, GL_FALSE, 0, 0);

	glDrawElements(GL_TRIANGLE_STRIP, nVertices, GL_UNSIGNED_INT, circleIndices);
	
	glBindVertexArrayOES(0);
}

@end