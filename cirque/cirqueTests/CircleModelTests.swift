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
		var points = [CGPointMake(105.0, 98.0),
									CGPointMake(-95.0, 98.0),
									CGPointMake(-95.0, -102.0),
									CGPointMake(105.0, -102.0)]
		var c = Circle()
		var polar = c.polarizePoints(points, around: CGPointMake(5.0, -2.0))
		
		XCTAssertEqualWithAccuracy(polar[0].a, CGFloat(1.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[0].r, CGFloat(141.0), 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[1].a, CGFloat(3.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[1].r, CGFloat(141.0), 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[2].a, CGFloat(-3.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[2].r, CGFloat(141.0), 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[3].a, CGFloat(-1.0 * M_PI_4), 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[3].r, CGFloat(141.0), 1.0, "Incorrectly polarized")
	}

	
	func testShouldCalculateDeviationsFromFitCircle() {
		var points: PolarArray = [	(a: 0.0, r: 100.0),
																(a: 90.0, r: 95.0),
																(a: 180.0, r: 105.0),
																(a: 270.0, r: 150.0)]
		
		var c = Circle()
		var deviations = c.deviationsFromFit(polarPoints: points, radius: CGFloat(100.0))
		XCTAssertEqualWithAccuracy(deviations[0], CGFloat(0.0), 0.0, "Deviation incorrect")
		XCTAssertEqualWithAccuracy(deviations[1], CGFloat(-5.0), 0.0, "Deviation incorrect")
		XCTAssertEqualWithAccuracy(deviations[2], CGFloat(5.0), 0.0, "Deviation incorrect")
		XCTAssertEqualWithAccuracy(deviations[3], CGFloat(50.0), 0.0, "Deviation incorrect")
	}
}
