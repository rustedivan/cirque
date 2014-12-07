//
//  TrailTests.swift
//  cirque
//
//  Created by Ivan Milles on 07/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import XCTest
import CoreGraphics.CGGeometry

class TrailTests: XCTestCase {

	override func setUp() {
			super.setUp()
			// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
			// Put teardown code here. This method is called after the invocation of each test method in the class.
			super.tearDown()
	}

	func testTrailWithOutSegmentHasNoAngles() {
		var t = Trail()
		XCTAssertEqual(t.segmentAngles().count, 0, "Degenerate trail should have no angles")
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		XCTAssertEqual(t.segmentAngles().count, 0, "Degenerate trail should have no angles")
	}

	func testTrailGeneratesAnglesForAllSegments() {
		var t = Trail()
		
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		XCTAssertEqual(t.segmentAngles().count, 2, "Trail should have one angle per point")
		
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		XCTAssertEqual(t.segmentAngles().count, 3, "Trail should have one angle per point")
	}

	func testTrailShouldGenerateIntermediateAngles() {
		var t = Trail()
		
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 100.0))
		let angles = t.segmentAngles()
		XCTAssertEqualWithAccuracy(angles[1], Float(M_PI_4), 0.01, "Segment should be angled between its neighbours")
	}
	
	func testTrailShouldHaveAngledEndSegments() {
		var t = Trail()
		
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 100.0))
		let angles = t.segmentAngles()
		XCTAssertEqualWithAccuracy(angles[0], Float(0.0), 0.01, "End point should point at its neighbor")
		XCTAssertEqualWithAccuracy(angles[2], Float(M_PI_2), 0.01, "End point should point at its neighbor")
	}
}
