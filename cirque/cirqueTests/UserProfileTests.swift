//
//  UserProfileTests.swift
//  cirque
//
//  Created by Ivan Milles on 2017-04-23.
//  Copyright © 2017 Rusted. All rights reserved.
//

import XCTest

class UserProfileTests: XCTestCase {
	func testShouldReleaseEffortHint() {
		let user = UserProfile()
		user.addEffort()
		
		XCTAssertFalse(user.canReleaseHint())
		XCTAssertFalse(user.releaseHint())
		XCTAssertEqual(user.effortPoints, 1)
		
		for _ in 0..<10 {
			user.addEffort()
		}
		
		XCTAssertTrue(user.releaseHint())
		XCTAssertEqual(user.effortPoints, 0)
	}
	
	func testShouldReleaseSkillVideo() {
		let user = UserProfile()
		user.addSkill(1.0)
		
		XCTAssertFalse(user.canReleaseHint())
		XCTAssertFalse(user.releaseHint())
		XCTAssertEqualWithAccuracy(user.skillPoints, 1.0, accuracy: 0.01)
		
		for _ in 0..<100 {
			user.addSkill(1.0)
		}
		
		XCTAssertTrue(user.releaseVideo())
		XCTAssertEqualWithAccuracy(user.skillPoints, 1.0, accuracy: 0.01)
	}
}
