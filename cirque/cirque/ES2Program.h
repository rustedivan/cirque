//
//  ES2Program.h
//  GripMath
//
//  Created by Ivan Milles on 2011-08-23.
//  Copyright 2011 KTH. All rights reserved.
//

#pragma once

#import <GLKit/GLKit.h>

enum {
	ATTRIB_POSITION_LOC,
	ATTRIB_TEXCOORD_LOC,
	ATTRIB_OFFSET_LOC
};

@class GPUBuffer;
@interface ES2Program : NSObject
{
	GLuint programID;
	GLuint vertexShader, fragmentShader;
	uint boundSamplers;
	NSString *vertexShaderName, *fragmentShaderName;
	NSString *debugName;
	
	NSMutableDictionary *shaderBinding;
}
@property GLuint vertexShader;
@property GLuint fragmentShader;
@property (readonly) GLuint programID;

+(ES2Program *) currentProgram;
+(void) unbindProgram;

-(id) initWithVertexShader: (NSString *) vPath fragmentShader: (NSString *) fPath debugName: (NSString *) name;
-(BOOL) createProgramWithVertexShader: (NSString *) vPath fragmentShader: (NSString *) fPath;
-(void) use;
-(BOOL) compileShader: (NSString *) source asType: (GLenum) shaderType;
-(NSString *) loadShader: (NSString *) path;
-(BOOL) linkShaders;
-(int) getAttribute: (NSString *) name;
-(int) getUniform: (NSString *) name;

-(void) setUniform: (NSString *) name
					intValue: (int) value;

-(void) setUniform: (NSString *) name
				floatValue: (float) value;

-(void) setUniform: (NSString *) name
					 vectorX: (float) vecX
					 vectorY: (float) vecY;

-(void) setUniform: (NSString *) name
					 vectorX: (float) vecX
					 vectorY: (float) vecY
					 vectorZ: (float) vecZ;

-(void) setUniform: (NSString *) name
			 matrixValue: (GLKMatrix4) matrix;

@end
