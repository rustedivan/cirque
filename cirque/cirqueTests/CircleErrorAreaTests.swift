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
			let modelRadius: CGFloat = 100.0
			let errorTreshold: CGFloat = 4.0
			let around = CGPoint(x: 10.0, y: -20.0)
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
			
			let e = Circle.generateErrorArea(imperfectPoints,
			                                 around: around,
			                                 radius: modelRadius,
			                                 treshold: errorTreshold)
			
			XCTAssertEqual(e.center, around)
			XCTAssertEqual(e.fitRadius, modelRadius)
			
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
	
	func testGenerateErrorTriangles() {
		let modelRadius: CGFloat = 100.0
		let errorTreshold: CGFloat = 4.0
		let around = CGPoint(x: 10.0, y: -20.0)
		var imperfectPoints: [Polar] = []
		imperfectPoints.append(Polar(a:  0.0, r: 100.0))	// In range
		imperfectPoints.append(Polar(a:  0.1, r: 101.0))	// In range
		imperfectPoints.append(Polar(a:  0.2, r: 108.0))	// Positive overshoot
		imperfectPoints.append(Polar(a:  0.3, r: 110.0))	// Positive overshoot
		imperfectPoints.append(Polar(a:  0.4, r:  90.0))	// Negative overshoot
		imperfectPoints.append(Polar(a:  0.5, r: 102.0))	// In range
		
		let e = Circle.generateErrorArea(imperfectPoints,
		                                 around: around,
		                                 radius: modelRadius,
		                                 treshold: errorTreshold)
		let t = e.toVertices()
		XCTAssertEqual(t.count, 6 * 3, "Should have generated six triangles")
		
		func radius(_ v: CirqueVertex) -> CGFloat {
			let p = CGPoint(x: CGFloat(v.position.x) - around.x,
			                y: CGFloat(v.position.y) - around.y)
			let r = sqrt(p.x * p.x + p.y * p.y)
			return CGFloat(r)
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
