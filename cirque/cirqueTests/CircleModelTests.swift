//
//  CircleModelTests.swift
//  cirque
//
//  Created by Ivan Milles on 07/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import XCTest

class CircleModelTests: XCTestCase {
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testAddSegment() {
		let circle = Circle()
		
		XCTAssertEqual(circle.segments.count, 0, "Circle didn't start out empty")
		
		circle.addSegment(0.0, radius: 100.0)
		circle.addSegment(0.707, radius: 120.0)

		XCTAssertEqual(circle.segments.count, 2, "Circle didn't add segments")
		XCTAssertEqual(circle.segments[0].radius, Float(100.0), "Circle didn't record segment properly")
		XCTAssertEqual(circle.segments[0].angle, Float(0.0), "Circle didn't record segment properly")
		XCTAssertEqual(circle.segments[1].radius, Float(120.0), "Circle didn't record segment properly")
		XCTAssertEqual(circle.segments[1].angle, Float(0.707), "Circle didn't record segment properly")
	}
}
