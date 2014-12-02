//
//  GameViewController.m
//  cirque
//
//  Created by Ivan Milles on 02/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

#include "GameViewController.h"
#include <GLKit/GLKit.h>

@implementation GameViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	if (!self.context) {
		NSLog(@"Failed to create ES context");
		return;
	}
	
	GLKView *view = (GLKView *) self.view;
	view.context = self.context;
	view.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
	view.drawableColorFormat = GLKViewDrawableColorFormatRGB565;
	view.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
	
	// Correct in landscape mode
	screenWidth = view.frame.size.width; // 320
	screenHeight = view.frame.size.height; // 480
	
	[self setupGL];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	[self tearDownGL];
	
	if ([EAGLContext currentContext] == self.context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	self.context = nil;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		return YES;
	}
	
	return NO;
}

- (void)setupGL {
	[EAGLContext setCurrentContext: self.context];
	glClearColor(1, 1, 0, 1);
}

- (void)tearDownGL {
	[EAGLContext setCurrentContext: self.context];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[touches enumerateObjectsUsingBlock: ^(id obj, BOOL *stop) {
		UITouch *touch = obj;
		CGPoint touchPoint = [touch locationInView:self.view];
		 
		CGPoint point;
		point.x = touchPoint.x;
		point.y = screenHeight - touchPoint.y;
		 
		oldPos = point;
	}];
}

-(void)glkView:(GLKView *)view drawInRect: (CGRect)rect {
	[((GLKView *) self.view) bindDrawable];
	glClear(GL_COLOR_BUFFER_BIT);
}

@end
