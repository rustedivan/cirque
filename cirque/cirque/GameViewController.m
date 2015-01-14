#include "GameViewController.h"
#include "CircleView.h"
#include "cirque-Swift.h"

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
	view.drawableMultisample = GLKViewDrawableMultisample4X;
	
	screenWidth = view.frame.size.width; // 320
	screenHeight = view.frame.size.height; // 480
	
	[self setupGL];
	
	_circleView = [[CircleView alloc] init];
	_circleView.viewSize = view.frame.size;
	_swCircleController = [[CircleController alloc] init];
}

- (void)tearDownGL {
	[EAGLContext setCurrentContext: self.context];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[touches enumerateObjectsUsingBlock: ^(id obj, BOOL *stop) {
		UITouch *touch = obj;
		CGPoint touchPoint = [touch locationInView:self.view];
		
		CGPoint point;
		point.x = touchPoint.x;
		point.y = screenHeight - touchPoint.y;
		
		_errorLabel.text = @"";
		_swCircleController = [[CircleController alloc] init];
		[_swCircleController beginNewCircle: point];
	}];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[touches enumerateObjectsUsingBlock: ^(id obj, BOOL *stop) {
		UITouch *touch = obj;
		CGPoint touchPoint = [touch locationInView:self.view];
		
		CGPoint point;
		point.x = touchPoint.x;
		point.y = screenHeight - touchPoint.y;
		
		[_swCircleController addSegment: point];
		
		oldPos = point;
	}];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[touches enumerateObjectsUsingBlock: ^(id obj, BOOL *stop) {
		UITouch *touch = obj;
		CGPoint touchPoint = [touch locationInView:self.view];
		
		CGPoint point;
		point.x = touchPoint.x;
		point.y = screenHeight - touchPoint.y;
		
		NSDictionary* result = [_swCircleController endCircle: point];
		if ([result[@"valid"] boolValue] == YES) {
			if (result[@"score"]) {
				NSInteger score = ([result[@"score"] floatValue] * 100.0f);
				[_errorLabel setText: [NSString stringWithFormat: @"Score: %ld", (long)score]];
			}
		} else {
			_swCircleController = nil;
		}
	}];
}

-(void)glkView:(GLKView *)view drawInRect: (CGRect)rect {
	[((GLKView *) self.view) bindDrawable];
	glClear(GL_COLOR_BUFFER_BIT);
	
	[_swCircleController draw: _circleView];
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
	glClearColor(1, 1, 1, 1);
}

@end
