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
	let examplePoints = [	CGPointMake(0.00, 0.00),
												CGPointMake(0.50, 0.25),
												CGPointMake(1.00, 1.00),
												CGPointMake(1.50, 2.25),
												CGPointMake(2.00, 4.00),
												CGPointMake(2.50, 6.25),
												CGPointMake(3.00, 9.00)]
	
	
	func testShouldCalculateCentroid() {
		let c = CircleFitter.centroid(examplePoints)
		XCTAssertEqualWithAccuracy(c.x, CGFloat(1.50), accuracy: 0.01, "Centroid not calculated correctly")
		XCTAssertEqualWithAccuracy(c.y, CGFloat(3.25), accuracy: 0.01, "Centroid not calculated correctly")
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

		XCTAssertEqualWithAccuracy(CircleFitter.sumUU(uv), CGFloat(7.00), accuracy: 0.01, "sUU not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumUV(uv), CGFloat(21.00), accuracy: 0.01, "sUV not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumVV(uv), CGFloat(68.25), accuracy: 0.01, "sVV not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumUUU(uv),	CGFloat(0.00), accuracy: 0.01, "sUUU not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumVVV(uv),	CGFloat(143.81), accuracy: 0.01, "sVVV not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumUVV(uv),	CGFloat(31.50), accuracy: 0.01, "sUVV not calculated correctly")
		XCTAssertEqualWithAccuracy(CircleFitter.sumUUV(uv),	CGFloat(5.25), accuracy: 0.01, "sVUU not calculated correctly")
	}
	
	func testShouldFitNewCenterAndRadius() {
		let newCenter = CircleFitter.fitCenterAndRadius(examplePoints)
		XCTAssertEqualWithAccuracy(newCenter.center.x, CGFloat(-11.84), accuracy: 0.01, "Center point not fitted correctly")
		XCTAssertEqualWithAccuracy(newCenter.center.y, CGFloat(8.45), accuracy: 0.01, "Center point not fitted correctly")
		XCTAssertEqualWithAccuracy(newCenter.radius, CGFloat(14.69), accuracy: 0.01, "Radius not fitter correctly")
	}
	
	func testCircleFitSpeed() {
		var p = Array<CGPoint>()
		for i in 0...10000 {
			let a = CGPointMake(CGFloat(i) * 2.0, CGFloat(i) * 3.0)
			p.append(a)
		}
		
		self.measureBlock() {
			CircleFitter.fitCenterAndRadius(p)
			return ()
		}
	}
}
