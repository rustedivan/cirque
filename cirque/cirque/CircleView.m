//
//  CircleView.m
//  cirque
//
//  Created by Ivan Milles on 03/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

#import "CircleView.h"
#import "cirque-Swift.h"

@implementation CircleView

-(void) render:(Circle *)model {
	NSLog(@"Rendering @ %.2f", model.radius);
}

@end
