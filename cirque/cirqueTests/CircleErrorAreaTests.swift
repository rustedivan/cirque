//
//  CircleErrorAreaTests.swift
//  cirque
//
//  Created by Ivan Milles on 29/05/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import XCTest

class CircleErrorAreaTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGenerateErrorArea() {
			let fit = CircleFit(Point(x: 10.0, y: -20.0), 100.0)
			let errorTreshold = 4.0
			var imperfectPoints: [Polar] = []
			imperfectPoints.append(Polar(a:  0.0, r: 100.0))	// In range
			imperfectPoints.append(Polar(a:  0.1, r: 101.0))	// In range
			imperfectPoints.append(Polar(a:  0.2, r: 108.0))	// Positive overshoot
			imperfectPoints.append(Polar(a:  0.3, r: 110.0))	// Positive overshoot
			imperfectPoints.append(Polar(a:  0.4, r:  90.0))	// Negative overshoot
			imperfectPoints.append(Polar(a:  0.5, r: 102.0))	// In range
			imperfectPoints.append(Polar(a:  0.6, r:  99.0))	// In range
			imperfectPoints.append(Polar(a:  0.7, r: 111.0))	// Positive overshoot
			imperfectPoints.append(Polar(a:  0.8, r: 112.0))	// Positive overshoot
			imperfectPoints.append(Polar(a:  0.9, r: 100.0))	// In range
			imperfectPoints.append(Polar(a:  0.10, r: 100.0))	// In range
			
			let e = ErrorArea(imperfectPoints,
			                  fit: fit,
												treshold: errorTreshold)

			XCTAssertEqual(e.fit.center.x, fit.center.x)
			XCTAssertEqual(e.fit.center.y, fit.center.y)
			XCTAssertEqual(e.fit.radius, fit.radius)
			
			XCTAssertEqual(e.errorBars.count, 9)
			
			XCTAssertEqual(e.errorBars[0].a, 0.1, "Did not place start cap correctly")
			XCTAssertEqual(e.errorBars[0].r, 100.0, "Did not place start cap correctly")

			XCTAssertEqual(e.errorBars[1].a, 0.2)
			XCTAssertEqual(e.errorBars[1].r, 108.0)

			XCTAssertEqual(e.errorBars[2].a, 0.3)
			XCTAssertEqual(e.errorBars[2].r, 110.0)

			XCTAssertEqual(e.errorBars[3].a, 0.4, "Did not place crossover correctly")
			XCTAssertEqual(e.errorBars[3].r, 90.0, "Did not handle crossover correctly")

			XCTAssertEqual(e.errorBars[4].a, 0.5, "Did not place end cap correctly")
			XCTAssertEqual(e.errorBars[4].r, 100.0, "Did not place end cap correctly")

			XCTAssertEqual(e.errorBars[5].a, 0.6, "Did not place start cap correctly")
			XCTAssertEqual(e.errorBars[5].r, 100.0, "Did not place start cap correctly")

			XCTAssertEqual(e.errorBars[6].a, 0.7)
			XCTAssertEqual(e.errorBars[6].r, 111.0)
			
			XCTAssertEqual(e.errorBars[7].a, 0.8)
			XCTAssertEqual(e.errorBars[7].r, 112.0)
			
			XCTAssertEqual(e.errorBars[8].a, 0.9, "Did not place end cap correctly")
			XCTAssertEqual(e.errorBars[8].r, 100.0, "Did not place end cap correctly")
	}
	
	func testShouldCaptureRootAngle() {
		let fit = CircleFit(Point(x: 10.0, y: -20.0), 100.0)
		let errorTreshold = 4.0
		var imperfectPoints: [Polar] = []
		imperfectPoints.append(Polar(a:  0.4, r: 100.0))	// In range
		imperfectPoints.append(Polar(a:  0.5, r: 101.0))	// In range
		imperfectPoints.append(Polar(a:  0.6, r: 108.0))	// Positive overshoot
		imperfectPoints.append(Polar(a:  0.7, r: 110.0))	// Positive overshoot
		imperfectPoints.append(Polar(a:  0.8, r:  90.0))	// Negative overshoot
		imperfectPoints.append(Polar(a:  0.9, r: 102.0))	// In range
		imperfectPoints.append(Polar(a:  1.0, r:  99.0))	// In range
		
		let e = ErrorArea(imperfectPoints,
		                  fit: fit,
		                  treshold: errorTreshold)
		
		XCTAssertEqual(e.rootAngle, 0.4, "Root angle is not that of first point (regardless of error area)")
	}
	
	func testGenerateErrorTriangles() {
		let fit = CircleFit(Point(x: 10.0, y: -20.0), 100.0)
		let errorTreshold = 4.0
		var imperfectPoints: [Polar] = []
		imperfectPoints.append(Polar(a:  0.0, r: 100.0))	// In range
		imperfectPoints.append(Polar(a:  0.1, r: 101.0))	// In range
		imperfectPoints.append(Polar(a:  0.2, r: 108.0))	// Positive overshoot
		imperfectPoints.append(Polar(a:  0.3, r: 110.0))	// Positive overshoot
		imperfectPoints.append(Polar(a:  0.4, r:  90.0))	// Negative overshoot
		imperfectPoints.append(Polar(a:  0.5, r: 102.0))	// In range
		
		let e = ErrorArea(imperfectPoints,
										  fit: fit,
										  treshold: errorTreshold)
		let t = e.toVertices()
		XCTAssertEqual(t.count, 6 * 3, "Should have generated six triangles")
		
		func radius(_ v: CirqueVertex) -> Double {
			let p = Point(x: Double(v.position.x) - fit.center.x,
										y: Double(v.position.y) - fit.center.y)
			let r = sqrt(p.x * p.x + p.y * p.y)
			return r
		}
		
		// Start cap triangle
		XCTAssertEqualWithAccuracy(radius(t[0]), 100.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[1]), 108.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[2]), 100.0, accuracy: 1.0)
		
		// Forward triangle #1
		XCTAssertEqualWithAccuracy(radius(t[3]), 108.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[4]), 110.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[5]), 100.0, accuracy: 1.0)
		
		// Backward triangle #2
		XCTAssertEqualWithAccuracy(radius(t[6]), 100.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[7]), 110.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[8]), 100.0, accuracy: 1.0)
		
		// Forward triangle #2
		XCTAssertEqualWithAccuracy(radius(t[9]), 110.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[10]), 100.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[11]), 100.0, accuracy: 1.0)
		
		// Backward triangle #3
		XCTAssertEqualWithAccuracy(radius(t[12]), 100.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[13]), 100.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[14]), 90.0, accuracy: 1.0)
		
		// End cap triangle
		XCTAssertEqualWithAccuracy(radius(t[15]), 100.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[16]), 100.0, accuracy: 1.0)
		XCTAssertEqualWithAccuracy(radius(t[17]), 90.0, accuracy: 1.0)
	}

}
