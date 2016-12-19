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
		let points = [Point(x: 105.0, y: -102.0),
									Point(x: -95.0, y: -102.0),
									Point(x: -95.0, y: 98.0),
									Point(x: 105.0, y: 98.0)]
		var polar = polarize(points, around: Point(x: 5.0, y: -2.0))
		
		XCTAssertEqualWithAccuracy(polar[0].a, 1.0 * M_PI_4, accuracy: 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[0].r, 141.0, accuracy: 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[1].a, 3.0 * M_PI_4, accuracy: 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[1].r, 141.0, accuracy: 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[2].a, 5.0 * M_PI_4, accuracy: 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[2].r, 141.0, accuracy: 1.0, "Incorrectly polarized")
		
		XCTAssertEqualWithAccuracy(polar[3].a, 7.0 * M_PI_4, accuracy: 0.01, "Incorrectly polarized")
		XCTAssertEqualWithAccuracy(polar[3].r, 141.0, accuracy: 1.0, "Incorrectly polarized")
	}
	
	func testCircleShouldFilterShortSegments() {
		var c = Circle()
		c.addSegment(zeroPoint)
		XCTAssertEqual(c.distanceFromEnd(Point(x: 10.0, y: 0.0)), 10.0, "Distance incorrect")
		XCTAssertEqual(c.distanceFromEnd(Point(x: 20.0, y: 0.0)), 20.0, "Distance incorrect")
		XCTAssertEqual(c.distanceFromEnd(Point(x: 1.0, y: 0.0)), 1.0, "Distance incorrect")
		XCTAssertEqual(c.distanceFromEnd(Point(x: 3.0, y: 4.0)), 5.0, "Distance incorrect")
	}
}
