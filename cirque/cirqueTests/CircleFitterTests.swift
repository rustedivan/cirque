//
//  CircleFitterTests.swift
//  cirque
//
//  Created by Ivan Milles on 13/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import XCTest
import CoreGraphics.CGGeometry

class CircleFitterTests: XCTestCase {
	let cf = CircleFitter()
// Points taken from http://www.dtcenter.org/met/users/docs/write_ups/circle_fit.pdf
	let examplePoints = [	Point(x: 0.00, y: 0.00),
												Point(x: 0.50, y: 0.25),
												Point(x: 1.00, y: 1.00),
												Point(x: 1.50, y: 2.25),
												Point(x: 2.00, y: 4.00),
												Point(x: 2.50, y: 6.25),
												Point(x: 3.00, y: 9.00)]
	
	
	func testShouldCalculateCentroid() {
		let c = CircleFitter.centroid(examplePoints)
		XCTAssertEqualWithAccuracy(c.x, 1.50, accuracy: 0.01, "Centroid not calculated correctly")
		XCTAssertEqualWithAccuracy(c.y, 3.25, accuracy: 0.01, "Centroid not calculated correctly")
	}
	
	func testShouldCalculateUVSpace() {
		let uv = CircleFitter.centerPoints(examplePoints)

		XCTAssertEqualWithAccuracy(uv[0].x, -1.50, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[0].y, -3.25, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[1].x, -1.00, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[1].y, -3.00, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[2].x, -0.50, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[2].y, -2.25, accuracy: 0.01, "Centering not done correctly")
	}
	
	func testShouldCalculateSums() {
		let uv = CircleFitter.centerPoints(examplePoints)

		XCTAssertEqualWithAccuracy(CircleFitter.sumUU(uv), 7.00, accuracy: 0.01, "sUU not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumUV(uv), 21.00, accuracy: 0.01, "sUV not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumVV(uv), 68.25, accuracy: 0.01, "sVV not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumUUU(uv),	0.00, accuracy: 0.01, "sUUU not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumVVV(uv),	143.81, accuracy: 0.01, "sVVV not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumUVV(uv),	31.50, accuracy: 0.01, "sUVV not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumUUV(uv),	5.25, accuracy: 0.01, "sVUU not calculated correctly")
	}
	
	func testShouldFitNewCenterAndRadius() {
		let newCenter = CircleFitter.fitCenterAndRadius(examplePoints)
		XCTAssertEqualWithAccuracy(newCenter.center.x, -11.84, accuracy: 0.01, "Center point not fitted correctly")
		XCTAssertEqualWithAccuracy(newCenter.center.y, 8.45, accuracy: 0.01, "Center point not fitted correctly")
		XCTAssertEqualWithAccuracy(newCenter.radius, 14.69, accuracy: 0.01, "Radius not fitter correctly")
	}
	
	func testCircleFitSpeed() {
		var p = Array<Point>()
		for i in 0...10000 {
			let a = Point(x: Double(i) * 2.0, y: Double(i) * 3.0)
			p.append(a)
		}
		
		self.measure() {
			let _ = CircleFitter.fitCenterAndRadius(p)
			return ()
		}
	}
}
