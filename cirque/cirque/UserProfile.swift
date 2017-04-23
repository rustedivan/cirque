//
//  UserProfile.swift
//  cirque
//
//  Created by Ivan Milles on 2017-04-23.
//  Copyright © 2017 Rusted. All rights reserved.
//

import Foundation

class UserProfile : NSObject, NSCoding {
	static let HintAvailableThreshold = 10
	static let VideoSkillPointCost = 100.0
	var effortPoints: Int = 0
	var skillPoints: Double = 0
	
	override init() {
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		effortPoints = aDecoder.decodeInteger(forKey: "effort")
		skillPoints = aDecoder.decodeDouble(forKey: "skill")
		super.init()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(effortPoints, forKey: "effort")
		aCoder.encode(skillPoints, forKey: "skill")
	}
	
	func addEffort() {
		if !canReleaseHint() {
			effortPoints += 1
		}
	}
	
	func canReleaseHint() -> Bool {
		return effortPoints >= UserProfile.HintAvailableThreshold
	}
	
	func releaseHint() -> Bool {
		guard canReleaseHint() else { return false }
		effortPoints = 0
		return true
	}
	
	func addSkill(_ normalizedSkill: Double) {
		skillPoints += normalizedSkill
	}
	
	func canReleaseVideo() -> Bool {
		return skillPoints >= UserProfile.VideoSkillPointCost
	}
	
	func releaseVideo() -> Bool {
		guard canReleaseVideo() else { return false }
		skillPoints -= UserProfile.VideoSkillPointCost
		return true
	}
}
