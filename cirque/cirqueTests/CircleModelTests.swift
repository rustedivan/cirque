//
//  CircleModelTests.swift
//  cirque
//
//  Created by Ivan Milles on 07/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import XCTest
import CoreGraphics.CGGeometry

class CircleModelTests: XCTestCase {
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testCircleShouldPolarizePoints() {
		var points = [CGPoint(x: 105.0, y: 98.0),
									CGPoint(x: -95.0, y: 98.0),
									CGPoint(x: -95.0, y: -102.0),
									CGPoint(x: 105.0, y: -102.0)]
		var c = Circle()
		var polar = c.polarizePoints(points, around: CGPointMake(5.0, -2.0))
		
		XCTAssertEqualWithAccuracy(polar[0].a, CGFloat(1.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[0].r, CGFloat(141.0), 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[1].a, CGFloat(3.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[1].r, CGFloat(141.0), 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[2].a, CGFloat(5.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[2].r, CGFloat(141.0), 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[3].a, CGFloat(7.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[3].r, CGFloat(141.0), 1.0, "Incorrectly polarized")
	}
}
