//
//  ScoreView.swift
//  cirque
//
//  Created by Ivan Milles on 27/03/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit

class UserProfileView: UIView {
	struct ViewModel {
		let effortString: String
		let skillString: String
		
		init(_ profile: UserProfile) {
			if profile.effortPoints <= 0 {
				effortString = ""
			} else if profile.canReleaseHint() {
				effortString = "Hint available"
			} else {
				effortString = "Hint: \(profile.effortPoints)/\(UserProfile.HintAvailableThreshold)"
			}
			
			if profile.skillPoints <= 0 {
				skillString = ""
			} else if profile.canReleaseVideo() {
				skillString = "Video available"
			} else {
				skillString = "Video: \(profile.skillPoints)/\(UserProfile.VideoSkillPointCost)"
			}
		}
	}

	var viewModel = ViewModel(UserProfile())
	@IBOutlet var effortLabel: UILabel!
	@IBOutlet var skillLabel: UILabel!
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func awakeFromNib() {
		presentProfile(UserProfile())
	}
	
	func presentProfile(_ profile: UserProfile) {
		viewModel = ViewModel(profile)
		
		effortLabel.text = viewModel.effortString
		skillLabel.text = viewModel.skillString
		layoutSubviews()
	}
}
