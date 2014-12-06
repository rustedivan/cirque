//
//  CircleView.h
//  cirque
//
//  Created by Ivan Milles on 03/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@class Circle;
@class ES2Program;
@interface CircleView : NSObject
@property (assign) CGSize viewSize;

-(void) render: (Circle *) model;
@end
