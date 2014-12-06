//
//  ES2Program.m
//  GripMath
//
//  Created by Ivan Milles on 2011-08-23.
//  Copyright 2011 KTH. All rights reserved.
//

#import "ES2Program.h"

static ES2Program *gCurrentProgram = nil;

@implementation ES2Program

@synthesize vertexShader;
@synthesize fragmentShader;
@synthesize programID;

-(id) initWithVertexShader: (NSString *) vPath fragmentShader: (NSString *) fPath debugName:(NSString *)name
{
	self = [super init];
	if (self)
	{
		if ([self createProgramWithVertexShader: vPath
														 fragmentShader: fPath])
		{
			debugName = name;
			boundSamplers = 0;
			shaderBinding = [[NSMutableDictionary alloc]init];
			return self;
		}
	}
	return nil;
}

NSString* shaderFileName (NSString *path)
{
	NSArray *components = [path componentsSeparatedByCharactersInSet: [NSCharacterSet punctuationCharacterSet]];
	return [components objectAtIndex: [components count] - 2];
}

-(BOOL) createProgramWithVertexShader: (NSString *) vPath fragmentShader: (NSString *) fPath
{
	NSString *vSource = [self loadShader: vPath];
	NSString *fSource = [self loadShader: fPath];
	if (!vSource || !fSource) return NO;
	
	vertexShaderName = shaderFileName(vPath);
	fragmentShaderName = shaderFileName(fPath);
	
	BOOL compiledVShader = [self compileShader: vSource asType: GL_VERTEX_SHADER];
	if (!compiledVShader)
	{
		NSLog(@"Error: Compile Vertex shader %@", vertexShaderName);
		return NO;
	}
	
	BOOL compiledFShader = [self compileShader: fSource asType: GL_FRAGMENT_SHADER];
	if (!compiledFShader)
	{
		NSLog(@"Error: Compile fragment shader %@", fragmentShaderName);
		NSLog(@"Source: %@", fSource);
		return NO;
	}
	
 
	BOOL linkedProgram = [self linkShaders];
	if (!linkedProgram) return NO;
	
	return YES;
	
}

-(BOOL) compileShader: (NSString *) source asType: (GLenum) shaderType
{
	// Create shader name
	GLuint shaderHandle = glCreateShader(shaderType);
	
	// Load shader source
	const char *shaderString = [source UTF8String];
	int len = (int)[source length];
	glShaderSource (shaderHandle, 1, &shaderString, &len);
	glCompileShader(shaderHandle);
	
	GLint compileSuccess;
	glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
	if (compileSuccess == GL_FALSE)
	{
		GLchar messages[256];
		glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
		NSString *messageString = [NSString stringWithUTF8String:messages];
		NSLog(@"Compile shader %@/%@: Error %@", vertexShaderName, fragmentShaderName, messageString);
		return FALSE;
	}
	
	if (GL_VERTEX_SHADER == shaderType) vertexShader = shaderHandle;
	if (GL_FRAGMENT_SHADER == shaderType) fragmentShader = shaderHandle;
	
	return TRUE;
}

-(NSString *) loadShader: (NSString *) path
{
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *resPath = [bundle resourcePath];
	NSString *shaderPath = [NSString stringWithFormat:@"%@/%@", resPath, path];
	
	NSError* error;
	NSString* shader;
	
	shader = [NSString stringWithContentsOfFile: shaderPath
																		 encoding: NSUTF8StringEncoding
																				error:&error];
	if (!shader)
	{
		NSLog (@"Could not load shader: %@", [error localizedDescription]);
		exit(1);
	}
	
	return shader;
}

-(BOOL) linkShaders
{
	if (!vertexShader || !fragmentShader) return NO;
	
	programID = glCreateProgram();
	glAttachShader(programID, vertexShader);
	glAttachShader(programID, fragmentShader);
	
	// Bind the positions of these three standard attribs/uniforms
	glBindAttribLocation(programID, ATTRIB_POSITION_LOC, "position");
	glBindAttribLocation(programID, ATTRIB_TEXCOORD_LOC, "texCoord");
	
	glLinkProgram(programID);
	
	GLint linkSuccess;
	glGetProgramiv(programID, GL_LINK_STATUS, &linkSuccess);
	if (linkSuccess == GL_FALSE) {
		GLchar messages[512];
		glGetProgramInfoLog (programID, sizeof(messages), 0, &messages[0]);
		NSString *messageString = [NSString stringWithUTF8String:messages];
		NSLog(@"Link error %@/%@: %@", vertexShaderName, fragmentShaderName, messageString);
		return NO;
	}
	
	// Release vertex and fragment shaders.
	if (vertexShader) {
		glDetachShader(programID, vertexShader);
		glDeleteShader(vertexShader);
	}
	if (fragmentShader) {
		glDetachShader(programID, fragmentShader);
		glDeleteShader(fragmentShader);
	}
	
	return YES;
}

-(void) use
{
	glUseProgram(programID);
	gCurrentProgram = self;
	boundSamplers = 0;
}

-(int) getAttribute: (NSString *) attribName
{
	int attrib = glGetAttribLocation (programID, [attribName UTF8String]);
	assert(attrib != -1);
	return attrib;
}

-(int) getUniform: (NSString *) uniformName
{
	int uniform = glGetUniformLocation (programID, [uniformName UTF8String]);
	//	assert(uniform != -1);
	return uniform;
}

-(void) setUniform: (NSString *) name
					intValue: (int) value
{
	glUniform1i ([self getUniform: name], value);
}

-(void) setUniform: (NSString *) name
				floatValue: (float) value
{
	glUniform1f([self getUniform: name], value);
}

-(void) setUniform: (NSString *) name
					 vectorX: (float) vecX
					 vectorY: (float) vecY
{
	glUniform2f([self getUniform:name], vecX, vecY);
}

-(void) setUniform: (NSString *) name
					 vectorX: (float) vecX
					 vectorY: (float) vecY
					 vectorZ: (float) vecZ
{
	glUniform3f([self getUniform:name], vecX, vecY, vecZ);
}

-(void) setUniform: (NSString *) name
			 matrixValue: (GLKMatrix4) matrix
{
	glUniformMatrix4fv([self getUniform:name], 1, 0, matrix.m);
}

-(void) debugInfo
{
	NSLog(@"Bindings for %@\n%@", debugName, shaderBinding);
}

+(ES2Program *) currentProgram
{
	return gCurrentProgram;
}

+(void) unbindProgram
{
	gCurrentProgram = nil;
}

+(void) initialize
{
	[ES2Program unbindProgram];
}

@end
