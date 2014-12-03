//
//  CircleView.h
//  cirque
//
//  Created by Ivan Milles on 03/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Circle;
@interface CircleView : NSObject
-(void) render: (Circle *) model;
@end
