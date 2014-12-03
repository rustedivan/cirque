//
//  GameViewController.h
//  cirque
//
//  Created by Ivan Milles on 02/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@class CircleView;
@class CircleController;
@interface GameViewController : GLKViewController
{
	int screenWidth;
	int screenHeight;
	
	CGPoint oldPos;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong, nonatomic) CircleView *circleView;
@property (strong, nonatomic) CircleController *swCircleController;

- (void)setupGL;
- (void)tearDownGL;
@end