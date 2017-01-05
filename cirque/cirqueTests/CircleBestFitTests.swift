//
//  CircleBestFitTests.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-09.
//  Copyright © 2016 Rusted. All rights reserved.
//

import XCTest

class CircleBestFitTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func testGeneratePartialRing() {
		func generateTestFitCircle(a0: Double) -> ((Double) -> (BestFitCircle)) {
			let around = Point(x: 10.0, y: -20.0)
			
			let taper = Taper(taperRatio: 0.1, clockwise: false)
			
			return { (p: Double) in
				BestFitCircle(fit: CircleFit(around, 100.0), startAngle: a0, progress: p, taper: taper)
			}
		}
		
		let genNoOverlap = generateTestFitCircle(a0: 0.0)
		
		let noRing = genNoOverlap(0.0)
		XCTAssertEqual(noRing.lineWidths.count, 1)
		XCTAssertEqualWithAccuracy(noRing.lineWidths.first!.a, 0.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(noRing.lineWidths.last!.a, 0.0, accuracy: 0.01)
		
		let quarterRing = genNoOverlap(0.25)
		XCTAssertEqual(quarterRing.lineWidths.count, 90 + 1)
		XCTAssertEqualWithAccuracy(quarterRing.lineWidths.first!.a, 0.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(quarterRing.lineWidths.last!.a, 1.57, accuracy: 0.01)
		
		let halfRing = genNoOverlap(0.5)
		XCTAssertEqual(halfRing.lineWidths.count, 180 + 1)
		XCTAssertEqualWithAccuracy(halfRing.lineWidths.first!.a, 0.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(halfRing.lineWidths.last!.a, 3.14, accuracy: 0.01)
		
		let threeQuarterRing = genNoOverlap(0.75)
		XCTAssertEqual(threeQuarterRing.lineWidths.count, 270 + 1)
		XCTAssertEqualWithAccuracy(threeQuarterRing.lineWidths.first!.a, 0.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(threeQuarterRing.lineWidths.last!.a, 4.71, accuracy: 0.01)
		
		let fullRing = genNoOverlap(1.0)
		XCTAssertEqual(fullRing.lineWidths.count, 360 + 1)
		XCTAssertEqualWithAccuracy(fullRing.lineWidths.first!.a, 0.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(fullRing.lineWidths.last!.a, 6.28, accuracy: 0.01)
	}
	
	func testGenerateOffsetRing() {
		func generateTestFitCircle(p: Double) -> ((Double) -> (BestFitCircle)) {
			let around = Point(x: 10.0, y: -20.0)
			let taper = Taper(taperRatio: 0.1, clockwise: false)
			
			return { (a0: Double) in
				BestFitCircle(fit: CircleFit(around, 100.0), startAngle: a0, progress: p, taper: taper)
			}
		}
		
		let genHalfRing = generateTestFitCircle(p: 0.5)
		
		let noOffset = genHalfRing(0.0)
		XCTAssertEqual(noOffset.lineWidths.count, 180 + 1)
		XCTAssertEqualWithAccuracy(noOffset.lineWidths.first!.a, 0.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(noOffset.lineWidths.last!.a, 3.14, accuracy: 0.01)
		
		let quarterOffset = genHalfRing(1.57)
		XCTAssertEqualWithAccuracy(quarterOffset.lineWidths.first!.a, 1.57, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(quarterOffset.lineWidths.last!.a, 4.71, accuracy: 0.01)
		
		let halfOffset = genHalfRing(3.14)
		XCTAssertEqualWithAccuracy(halfOffset.lineWidths.first!.a, 3.14, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(halfOffset.lineWidths.last!.a, 6.28, accuracy: 0.01)
		
		let threeQuarterOffset = genHalfRing(4.71)
		XCTAssertEqualWithAccuracy(threeQuarterOffset.lineWidths.first!.a, 4.71, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(threeQuarterOffset.lineWidths.last!.a, 7.85, accuracy: 0.01)
		
		let fullOffset = genHalfRing(6.28)
		XCTAssertEqualWithAccuracy(fullOffset.lineWidths.first!.a, 6.28, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(fullOffset.lineWidths.last!.a, 9.42, accuracy: 0.01)
	}
	
	func testGenerateTaperedRing() {
		func generateTestFitCircle(a0: Double, taper: Double) -> ((Double) -> (BestFitCircle)) {
			let around = Point(x: 10.0, y: -20.0)
			let taper = Taper(taperRatio: taper, clockwise: false)
			
			return { (p: Double) in
				BestFitCircle(fit: CircleFit(around, 100.0), startAngle: a0, progress: p, taper: taper)
			}
		}
		
		let taperRatio = 0.1
		let genTaperRing = generateTestFitCircle(a0: 0.0, taper: taperRatio)
		
		let noTaper = genTaperRing(0.0)
		// Only one segment, no width
		XCTAssertEqualWithAccuracy(noTaper.lineWidths.first!.w, 1.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(noTaper.lineWidths.last!.w, 1.0, accuracy: 0.01)
		
		let partialTaper = genTaperRing(taperRatio / 1.5)
		XCTAssertEqualWithAccuracy(partialTaper.lineWidths.first!.w, 1.0, accuracy: 0.01)
		XCTAssertLessThan(partialTaper.lineWidths[22].w, 1.0)
		XCTAssertEqualWithAccuracy(partialTaper.lineWidths.last!.w, 0.0, accuracy: 0.01)
		
		let onlyTaper = genTaperRing(taperRatio)
		XCTAssertEqualWithAccuracy(onlyTaper.lineWidths.first!.w, 1.0, accuracy: 0.01)
		XCTAssertLessThan(onlyTaper.lineWidths[34].w, 1.0)
		XCTAssertEqualWithAccuracy(onlyTaper.lineWidths.last!.w, 0.0, accuracy: 0.01)
		
		let partialWithTaper = genTaperRing(taperRatio + 0.1)
		// Full taper, rest of ring is full width
		XCTAssertEqualWithAccuracy(partialWithTaper.lineWidths.first!.w, 1.0, accuracy: 0.01)
		XCTAssertLessThan(partialWithTaper.lineWidths[68].w, 1.0)
		XCTAssertEqualWithAccuracy(partialWithTaper.lineWidths.last!.w, 0.0, accuracy: 0.01)
		
		let fullWithTaper = genTaperRing(1.0)
		// Ring ends in a point
		XCTAssertEqualWithAccuracy(fullWithTaper.lineWidths.first!.w, 1.0, accuracy: 0.01)
		XCTAssertLessThan(fullWithTaper.lineWidths[342].w, 1.0)
		XCTAssertEqualWithAccuracy(fullWithTaper.lineWidths.last!.w, 0.0, accuracy: 0.01)
	}
	
	func testGenerateClockwiseRing() {
		func generateTestFitCircle(a0: Double, taper: Double) -> ((Double) -> (BestFitCircle)) {
			let around = Point(x: 10.0, y: -20.0)
			let taper = Taper(taperRatio: 0.1, clockwise: true)
			
			return { (p: Double) in
				BestFitCircle(fit: CircleFit(around, 100.0), startAngle: a0, progress: p, taper: taper)
			}
		}
		
		let taperRatio = 0.1
		let genTaperCWRing = generateTestFitCircle(a0: 1.57, taper: taperRatio)
		
		let noTaper = genTaperCWRing(0.0)
		XCTAssertEqualWithAccuracy(noTaper.lineWidths.first!.w, 1.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(noTaper.lineWidths.first!.a, 1.57, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(noTaper.lineWidths.last!.w, 1.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(noTaper.lineWidths.last!.a, 1.57, accuracy: 0.01)
		
		let quarterArc = genTaperCWRing(0.25)
		XCTAssertEqualWithAccuracy(quarterArc.lineWidths.first!.w, 1.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(quarterArc.lineWidths.first!.a, 1.57, accuracy: 0.01)
		// 90 segments, taper over last 9 segments, check half-way
		XCTAssertLessThan(quarterArc.lineWidths[85].w, 1.0)
		XCTAssertEqualWithAccuracy(quarterArc.lineWidths[45].a, 0.78, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(quarterArc.lineWidths.last!.w, 0.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(quarterArc.lineWidths.last!.a, 0.0, accuracy: 0.01)
		
		let halfCircle = genTaperCWRing(0.5)
		XCTAssertEqualWithAccuracy(halfCircle.lineWidths.first!.w, 1.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(halfCircle.lineWidths.first!.a, 1.57, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(halfCircle.lineWidths[90].w, 1.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(halfCircle.lineWidths[90].a, 0.00, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(halfCircle.lineWidths.last!.w, 0.0, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(halfCircle.lineWidths.last!.a, -1.57, accuracy: 0.01)
		
		let fullWithTaper = genTaperCWRing(1.0)
		XCTAssertEqualWithAccuracy(fullWithTaper.lineWidths.first!.a, 1.57, accuracy: 0.01)
		XCTAssertEqualWithAccuracy(fullWithTaper.lineWidths.last!.a, -4.71, accuracy: 0.01)
	}
	
	func testGenerateBestFitTriangles() {
		let fit = CircleFit(Point(x: 10.0, y: -20.0), 100.0)
		
		let taper = Taper(taperRatio: 0.2, clockwise: false)
		var f = BestFitCircle(fit: fit, startAngle: 0.2, progress: 0.8, taper: taper)
		f.bestFitWidth = 2.0
		let t = f.toVertices()
		XCTAssertEqual(t.count, 289 * 2, "Should have generated 361 segments of two vertices each")
		
		func radius(_ v: CirqueVertex) -> Double {
			let p = Point(x: Double(v.position.x) - fit.center.x,
			              y: Double(v.position.y) - fit.center.y)
			let r = sqrt(p.x * p.x + p.y * p.y)
			return r
		}
		
		// Beginning of ring has full width
		// First vertex inside radius, second outside
		XCTAssertEqualWithAccuracy(radius(t[0]), 99.0, accuracy: 0.1)
		XCTAssertEqualWithAccuracy(radius(t[1]), 101.0, accuracy: 0.1)
		
		// Middle of ring still has full width
		XCTAssertEqualWithAccuracy(radius(t[184]), 99.0, accuracy: 0.1)
		XCTAssertEqualWithAccuracy(radius(t[185]), 101.0, accuracy: 0.1)
		
		// End of ring starts tapering
		XCTAssertEqualWithAccuracy(radius(t[540]), 99.7, accuracy: 0.1)
		XCTAssertEqualWithAccuracy(radius(t[541]), 100.3, accuracy: 0.1)
		
		// End of ring comes to a point
		XCTAssertEqualWithAccuracy(radius(t[572]), 100.0, accuracy: 0.1)
		XCTAssertEqualWithAccuracy(radius(t[573]), 100.0, accuracy: 0.1)
	}
}
