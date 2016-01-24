//
//  CircleView.m
//  cirque
//
//  Created by Ivan Milles on 03/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

//#import "CircleView.h"
//#import "ES2Program.h"
//#import <OpenGLES/ES2/gl.h>
//#import <OpenGLES/ES2/glext.h>
//#import "cirque-Swift.h"
//
//@interface CircleView ()
//@property (strong) ES2Program* circleShader;
//@property GLuint circleVertexArray;
//@property GLuint circleVertexBuffer;
//
//@property (strong) ES2Program* fitShader;
//@property GLuint fitVertexArray;
//@property GLuint fitVertexBuffer;
//
//@end
//
//@implementation CircleView
//
//-(id) init {
//	if (self = [super init]) {
//
//		_circleShader = [[ES2Program alloc] initWithVertexShader:@"Shader.vsh" fragmentShader:@"Shader.fsh" debugName:@"Circle shader"];
//		glGenVertexArraysOES(1, &_circleVertexArray);
//		assert(glGetError() == GL_NO_ERROR && "Setup circle vertex data failed");
//		glGenBuffers(1, &_circleVertexBuffer);
//		assert(glGetError() == GL_NO_ERROR && "Setup circle vertex data failed");
//
//		_fitShader = [[ES2Program alloc] initWithVertexShader:@"Shader.vsh" fragmentShader:@"Shader.fsh" debugName:@"Circle shader"];
//		glGenVertexArraysOES(1, &_fitVertexArray);
//		assert(glGetError() == GL_NO_ERROR && "Setup circle vertex data failed");
//		glGenBuffers(1, &_fitVertexBuffer);
//		assert(glGetError() == GL_NO_ERROR && "Setup circle vertex data failed");
//
//	
//	}
//	return self;
//}
//
//-(void) render:(Circle *)model {
//	[_circleShader use];
//	
//	GLKMatrix4 mvpMatrix = GLKMatrix4MakeOrtho(0, _viewSize.width, 0, _viewSize.height,  10, -10);
//	[_circleShader setUniform: @"modelViewProjectionMatrix" matrixValue: mvpMatrix];
//	[_circleShader setUniform: @"color" vectorX:0.0 vectorY:0.0 vectorZ:0.6];
//	
//	// FIXME: Crazy to do this per-frame. Memory-map a buffer?
//	Trail* trail = model.segments;
//	int nSegments = (int) trail.nPoints;
//	
//	if (nSegments < 2) return;
//	
//	int nVertices = nSegments * 2;
//	int nCoords = nVertices * 2;
//	int circleIndices[nVertices];
//	float coords[nCoords];
//
//	int vertexIndex = 0;
//	int coordIndex = 0;
//	float thickness = 4.0f;
//
//	NSArray* angles = trail.angles;
//	NSArray* distances = trail.distances;
//	
//	for (int i = 0; i < nSegments; i++) {
//		float a = ((NSNumber *)angles[i]).floatValue;
//		float d = ((NSNumber *)distances[i]).floatValue;
//		
//		// Given center point pC and angle, calculate left and right points pL and pR
//		CGFloat width = thickness + log2(d);
//		CGVector span = CGVectorMake(sin(a) * width / 2.0f, -cos(a) * width / 2.0f);
//		CGPoint pC = [trail point:i];
//		CGPoint pL = CGPointMake(pC.x + span.dx, pC.y + span.dy);
//		CGPoint pR = CGPointMake(pC.x - span.dx, pC.y - span.dy);
//		
//		// Add the two vertices
//		circleIndices[vertexIndex] = vertexIndex;		vertexIndex++;
//		coords[coordIndex] = pL.x;	coordIndex++;
//		coords[coordIndex] = pL.y;	coordIndex++;
//
//		circleIndices[vertexIndex] = vertexIndex;		vertexIndex++;
//		coords[coordIndex] = pR.x;	coordIndex++;
//		coords[coordIndex] = pR.y;	coordIndex++;
//	}
//	
//	glBindVertexArrayOES(_circleVertexArray);
//	glBindBuffer(GL_ARRAY_BUFFER, _circleVertexBuffer);
//	glBufferData(GL_ARRAY_BUFFER, nCoords * sizeof(float), coords, GL_DYNAMIC_DRAW);
//	
//	glEnableVertexAttribArray([_circleShader getAttribute:@"position"]);
//	glVertexAttribPointer([_circleShader getAttribute:@"position"], 2, GL_FLOAT, GL_FALSE, 0, 0);
//
//	glDrawElements(GL_TRIANGLE_STRIP, nVertices, GL_UNSIGNED_INT, circleIndices);
//	
//	glBindVertexArrayOES(0);
//}
//
//-(void) renderFitWithRadius: (CGFloat) r
//												 at: (CGPoint) c
//{
//	[_fitShader use];
//	GLKMatrix4 mvpMatrix = GLKMatrix4MakeOrtho(0, _viewSize.width, 0, _viewSize.height,  10, -10);
//	[_fitShader setUniform: @"modelViewProjectionMatrix" matrixValue: mvpMatrix];
//	[_circleShader setUniform: @"color" vectorX:0.0 vectorY:0.8 vectorZ:0.2];
//
//	// FIXME: Crazy to do this per-frame. Memory-map a buffer?
//	int resolution = 90;
//	int nSegments = resolution + 1;
//	int nVertices = nSegments * 2;
//	int nCoords = nVertices * 2;
//	int fitIndices[nVertices];
//	float coords[nCoords];
//	
//	int vertexIndex = 0;
//	int coordIndex = 0;
//	float thickness = 1.0f;
//	float a = 0.0f;
//	float dA = (2.0 * M_PI) / (float)resolution;
//	for (int i = 0; i < nSegments; i++) {
//		// Given center point pC and angle, calculate left and right points pL and pR
//		CGVector span = CGVectorMake(sin(a + M_PI_2) * thickness / 2.0f, -cos(a + M_PI_2) * thickness / 2.0f);
//		CGPoint pC = CGPointMake(c.x + cos(a) * r, c.y + sin(a) * r);
//		CGPoint pL = CGPointMake(pC.x + span.dx, pC.y + span.dy);
//		CGPoint pR = CGPointMake(pC.x - span.dx, pC.y - span.dy);
//		
//		// Add the two vertices
//		fitIndices[vertexIndex] = vertexIndex;		vertexIndex++;
//		coords[coordIndex] = pL.x;	coordIndex++;
//		coords[coordIndex] = pL.y;	coordIndex++;
//		
//		fitIndices[vertexIndex] = vertexIndex;		vertexIndex++;
//		coords[coordIndex] = pR.x;	coordIndex++;
//		coords[coordIndex] = pR.y;	coordIndex++;
//
//		a += dA;
//	}
//	
//	glBindVertexArrayOES(_fitVertexArray);
//	glBindBuffer(GL_ARRAY_BUFFER, _fitVertexBuffer);
//	glBufferData(GL_ARRAY_BUFFER, nCoords * sizeof(float), coords, GL_DYNAMIC_DRAW);
//	
//	glEnableVertexAttribArray([_fitShader getAttribute:@"position"]);
//	glVertexAttribPointer([_fitShader getAttribute:@"position"], 2, GL_FLOAT, GL_FALSE, 0, 0);
//	
//	glDrawElements(GL_TRIANGLE_STRIP, nVertices, GL_UNSIGNED_INT, fitIndices);
//	
//	glBindVertexArrayOES(0);
//}
//
//@end
