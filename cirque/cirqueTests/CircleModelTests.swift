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

	func testCircleShouldCalculateCentroid() {
		var c = Circle()
		var p: CGPoint

		p = c.calculateCentroid([	CGPointMake(100.0, 0.0),
															CGPointMake(-100.0, 0.0)])
		XCTAssertEqualWithAccuracy(p.x, CGFloat(0.0), 0.01, "Centroid incorrect")
		XCTAssertEqualWithAccuracy(p.y, CGFloat(0.0), 0.01, "Centroid incorrect")
		
		p = c.calculateCentroid([	CGPointMake(100.0, 0.0),
															CGPointMake(-100.0, 0.0),
															CGPointMake(60.0, 30.0)])
		XCTAssertEqualWithAccuracy(p.x, CGFloat(20.0), 0.01, "Centroid incorrect")
		XCTAssertEqualWithAccuracy(p.y, CGFloat(10.0), 0.01, "Centroid incorrect")
	}
	
	func testCircleShouldPolarizePoints() {
		var points = [CGPointMake(100.0, 100.0),
									CGPointMake(-100.0, 100.0),
									CGPointMake(-100.0, -100.0),
									CGPointMake(100.0, -100.0)]
		var c = Circle()
		var polar = c.polarizePoints(points)
		
		XCTAssertEqualWithAccuracy(polar[0].a, Float(1.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[0].r, Float(141.0), 1.0, "Incorrectly polarized")

		XCTAssertEqualWithAccuracy(polar[1].a, Float(3.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[1].r, Float(141.0), 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[2].a, Float(-3.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[2].r, Float(141.0), 1.0, "Incorrectly polarized")

		XCTAssertEqualWithAccuracy(polar[3].a, Float(-1.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[3].r, Float(141.0), 1.0, "Incorrectly polarized")
	}
}
