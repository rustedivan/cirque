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
		t.addPoint(Point(x: 0.0, y: 0.0))
		XCTAssertEqual(t.angles.count, 0, "Degenerate trail should have no angles")
	}

	func testTrailGeneratesAnglesForAllSegments() {
		var t = Trail()
		
		t.addPoint(Point(x: 0.0, y: 0.0))
		t.addPoint(Point(x: 100.0, y: 0.0))
		XCTAssertEqual(t.angles.count, 2, "Trail should have one angle per point")
		
		t.addPoint(Point(x: 150.0, y: 0.0))
		XCTAssertEqual(t.angles.count, 3, "Trail should have one angle per point")
	}

	func testTrailShouldGenerateIntermediateAngles() {
		var t = Trail()
		
		t.addPoint(Point(x: 0.0, y: 0.0))
		t.addPoint(Point(x: 100.0, y: 0.0))
		t.addPoint(Point(x: 100.0, y: 100.0))
		let angles = t.angles
		XCTAssertEqualWithAccuracy(angles[1], M_PI_4, accuracy: 0.01, "Segment should be angled between its neighbours")
	}
	
	func testTrailShouldHaveAngledEndSegments() {
		var t = Trail()
		
		t.addPoint(Point(x: 0.0, y: 0.0))
		t.addPoint(Point(x: 100.0, y: 0.0))
		t.addPoint(Point(x: 100.0, y: 100.0))
		let angles = t.angles
		XCTAssertEqualWithAccuracy(angles[0], 0.0, accuracy: 0.01, "End point should point at its neighbor")
		XCTAssertEqualWithAccuracy(angles[2], M_PI_2, accuracy: 0.01, "End point should point at its neighbor")
	}
	
	func testTrailShouldRecalculateTrailEndWhenExtending() {
		var t = Trail()
		
		t.addPoint(Point(x: 0.0, y: 0.0))
		t.addPoint(Point(x: 10.0, y: 0.0))
		t.addPoint(Point(x: 20.0, y: 0.0))
		t.addPoint(Point(x: 30.0, y: 0.0))
		
		var angles = t.angles
		XCTAssertEqualWithAccuracy(angles[3], 0.0, accuracy: 0.01, "End point should be aligned")
		t.addPoint(Point(x: 30.0, y: 10.0))
		angles = t.angles
		XCTAssertEqualWithAccuracy(angles[4], M_PI_2, accuracy: 0.01, "New end point should be aligned")
		XCTAssertEqualWithAccuracy(angles[3], M_PI_4, accuracy: 0.01, "Last end point should be updated")
	}
	
	func testTrailGeneratesDistancesBetweenSegments() {
		var t = Trail()
		
		t.addPoint(Point(x: 0.0, y: 0.0))
		t.addPoint(Point(x: 100.0, y: 0.0))
		XCTAssertEqual(t.distances.count, 2, "Trail should have one distance per point-pair")
		XCTAssertEqual(t.distances.last!, 100.0, "Trail should calculate correct distance")
		
		t.addPoint(Point(x: 100.0, y: 50.0))
		XCTAssertEqual(t.distances.count, 3, "Trail should have one distance per point-pair")
		XCTAssertEqual(t.distances.last!, 50.0, "Trail should calculate correct distance")
	}
	
	func testTrailShouldPolarizePoints() {
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
	
	func testTrailShouldFilterShortSegments() {
		var t = Trail()
		t.addPoint(zeroPoint)
		XCTAssertEqual(t.distanceFromEnd(Point(x: 10.0, y: 0.0)), 10.0, "Distance incorrect")
		XCTAssertEqual(t.distanceFromEnd(Point(x: 20.0, y: 0.0)), 20.0, "Distance incorrect")
		XCTAssertEqual(t.distanceFromEnd(Point(x: 1.0, y: 0.0)), 1.0, "Distance incorrect")
		XCTAssertEqual(t.distanceFromEnd(Point(x: 3.0, y: 4.0)), 5.0, "Distance incorrect")
	}
}
