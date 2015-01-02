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
		XCTAssertEqual(t.angles.count, 0, "Degenerate trail should have no angles")
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		XCTAssertEqual(t.angles.count, 0, "Degenerate trail should have no angles")
	}

	func testTrailGeneratesAnglesForAllSegments() {
		var t = Trail()
		
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		XCTAssertEqual(t.angles.count, 2, "Trail should have one angle per point")
		
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		XCTAssertEqual(t.angles.count, 3, "Trail should have one angle per point")
	}

	func testTrailShouldGenerateIntermediateAngles() {
		var t = Trail()
		
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 100.0))
		let angles = t.angles
		XCTAssertEqualWithAccuracy(angles[1], CGFloat(M_PI_4), 0.01, "Segment should be angled between its neighbours")
	}
	
	func testTrailShouldHaveAngledEndSegments() {
		var t = Trail()
		
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 100.0))
		let angles = t.angles
		XCTAssertEqualWithAccuracy(angles[0], CGFloat(0.0), 0.01, "End point should point at its neighbor")
		XCTAssertEqualWithAccuracy(angles[2], CGFloat(M_PI_2), 0.01, "End point should point at its neighbor")
	}
	
	func testTrailShouldRecalculateTrailEndWhenExtending() {
		var t = Trail()
		
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		t.addPoint(CGPoint(x: 10.0, y: 0.0))
		t.addPoint(CGPoint(x: 20.0, y: 0.0))
		t.addPoint(CGPoint(x: 30.0, y: 0.0))
		
		var angles = t.angles
		XCTAssertEqualWithAccuracy(angles[3], CGFloat(0.0), 0.01, "End point should be aligned")
		t.addPoint(CGPoint(x: 30.0, y: 10.0))
		angles = t.angles
		XCTAssertEqualWithAccuracy(angles[4], CGFloat(M_PI_2), 0.01, "New end point should be aligned")
		XCTAssertEqualWithAccuracy(angles[3], CGFloat(M_PI_4), 0.01, "Last end point should be updated")
	}
	
	func testTrailGeneratesDistancesBetweenSegments() {
		var t = Trail()
		
		t.addPoint(CGPoint(x: 0.0, y: 0.0))
		t.addPoint(CGPoint(x: 100.0, y: 0.0))
		XCTAssertEqual(t.distances.count, 1, "Trail should have one distance per point-pair")
		XCTAssertEqual(t.distances.last!, CGFloat(100.0), "Trail should calculate correct distance")
		
		t.addPoint(CGPoint(x: 100.0, y: 50.0))
		XCTAssertEqual(t.distances.count, 2, "Trail should have one distance per point-pair")
		XCTAssertEqual(t.distances.last!, CGFloat(50.0), "Trail should calculate correct distance")
	}
}
