//
//  CircleViewTests.m
//  cirque
//
//  Created by Ivan Milles on 07/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface CircleViewTests : XCTestCase

@end

@implementation CircleViewTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testViewSegmentAngler {
	
	
	// If < 2 segments, do nothing
	// If 2 segments, both are angle 0 -> 1
	// If > 2 segments:
	//	0: angle 0 -> 1
	//  1: angle 0 -> 2
	//  2: angle 1 -> 3
	//  I: angle I-1 -> I+1
	//  N: angle N-1 -> N
	
	
}

@end
