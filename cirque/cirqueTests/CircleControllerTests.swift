//
//  CircleControllerTests.swift
//  cirque
//
//  Created by Ivan Milles on 04/01/15.
//  Copyright (c) 2015 Rusted. All rights reserved.
//

import XCTest

class CircleControllerTests: XCTestCase {
	let delayTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))

	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	// FIXME: These tests are currently broken due to compiler crash.
	
//	func testShouldFitCircleInBackgroundWhileDrawing() {
//		let expectation = expectationWithDescription("Did fit circle")
//		class MockCircleController: CircleController {
//			override func fitCircle(trail: Trail, cb: CircleFitCallback) {
//				dispatch_after(delayTime, dispatch_get_main_queue()) {
//					cb(nil)
//					// FIXME: The below line crashes swiftc
//					// expectation.fulfill()
//				}
//			}
//		}
//		let c = CircleController()
//		c.addSegment(CGPointZero)		// This should trigger analysis thread
//
//		waitForExpectationsWithTimeout(1.0, handler: nil)
//	}
//	
//	func testShouldOnlyFitCircleIfNoAnalysisIsPending() {
//		class MockCircleController: CircleController {
//			var dispatchCount = 0
//			override func dispatchFitJob(trail: Trail, cb: CircleFitCallback) {
//				dispatchCount++
//				dispatch_after(delayTime, dispatch_get_main_queue()) {
//					cb(nil)
//				}
//			}
//		}
//		
//		let c = MockCircleController()
//		c.addSegment(CGPointZero)
//		XCTAssertTrue(c.analysisRunning, "Analysis should be blocked now.")
//		XCTAssertEqual(c.dispatchCount, 1, "Only one fit call should have been made")
//		c.addSegment(CGPointZero)
//		XCTAssertTrue(c.analysisRunning, "Analysis should still be blocked now.")
//		XCTAssertEqual(c.dispatchCount, 1, "Only one fit call should have been made")
//		c.analysisRunning = false
//		c.addSegment(CGPointZero)
//		XCTAssertEqual(c.dispatchCount, 2, "The fit channel should be open now")
//	}
//	
//	func testShouldNotFitCircleThatIsOnlyASegment() {
//		XCTFail("Not implemented")
//	}
//	
//	func testShouldCopyTrailDataToThread() {
//		XCTFail("Not implemented")
//	}
}
