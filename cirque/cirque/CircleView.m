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
	mvpMatrix = GLKMatrix4Translate(mvpMatrix, 150, 150, 0);
	[_circleShader setUniform: @"modelViewProjectionMatrix" matrixValue: mvpMatrix];
	
	// $ Crazy to do this per-frame. Memory-map a buffer?
	int nV = (int) model.indices.count;
	int circleIndices[nV];
	float coords[nV * 2];
	for (int i = 0; i < nV; i++) {
		circleIndices[i] = i;
		float x = ((NSNumber *)model.vertices[2 * i + 0]).floatValue;
		float y = ((NSNumber *)model.vertices[2 * i + 1]).floatValue;
		coords[2 * i + 0] = x;
		coords[2 * i + 1] = y;
	}
	
	glBindVertexArrayOES(_vertexArray);
	glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, 2 * nV * sizeof(float), coords, GL_DYNAMIC_DRAW);
	
	glEnableVertexAttribArray([_circleShader getAttribute:@"position"]);
	glVertexAttribPointer([_circleShader getAttribute:@"position"], 2, GL_FLOAT, GL_FALSE, 0, 0);

	glDrawElements(GL_LINE_LOOP, nV, GL_UNSIGNED_INT, circleIndices);
	
	glBindVertexArrayOES(0);
}

@end
