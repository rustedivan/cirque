//
//  ScoreView.swift
//  cirque
//
//  Created by Ivan Milles on 27/03/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit

class ScoreView: UIView {
	struct ViewModel {
		var displaying: Bool
		var scoreString: String
	}
	
	var countUpStartTime: Date!
	var viewModel = ViewModel(displaying: false, scoreString: "")
	var targetScore: Int = 0 {
		didSet {
			startCountup()
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	convenience init(frame: CGRect, score: Int) {
		self.init(frame: frame)
		self.backgroundColor = UIColor.clear
		self.isOpaque = false
	}
	
	override func draw(_ rect: CGRect) {
		let scoreImage = percentageAsImage(viewModel.scoreString, imageWidth: rect.width)
		let center = Point(x: Double(rect.midX), y: Double(rect.midY))
		let centered = Point(x: center.x - Double(scoreImage.size.width) / 2.0, y: center.y - Double(scoreImage.size.height) / 2.0)
		let scoreRect = CGRect(origin: CGPoint(point: centered), size: scoreImage.size)
		
		scoreImage.draw(in: scoreRect)
	}
	
	func update() {
		if targetScore > 0 {
			viewModel.scoreString = "\(targetScore)%"
		} else {
			viewModel.scoreString = "X"
		}
		
		if (Date().timeIntervalSince(countUpStartTime) > 1.0) {
			viewModel.displaying = false
		}
		else {
			setNeedsDisplay()
		}
	}
	
	func startCountup() {
		self.countUpStartTime = Date()
	}
	
	func percentageAsImage(_ percentageString: String, imageWidth: CGFloat) -> UIImage {
		// $ Add test for this
		let fontSize = imageWidth / 2.35	// Linear estimate between image width and this particular font setup
		
		var fontAttributes: [String:AnyObject]
		if #available(iOS 8.2, *) {
			fontAttributes = [
				NSFontAttributeName : UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightLight),
				NSStrokeWidthAttributeName : 0.0 as AnyObject,
				NSForegroundColorAttributeName : UIColor.blue
			]
		} else {
			fontAttributes = [
				NSFontAttributeName : UIFont.systemFont(ofSize: fontSize),
				NSStrokeWidthAttributeName : 0.0 as AnyObject,
				NSForegroundColorAttributeName : UIColor.blue
			]
		}
		
		let string = NSString(string: percentageString)
		let size = string.size(attributes: fontAttributes)
		
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		defer { UIGraphicsEndImageContext() }
		
		string.draw(at: CGPoint.zero, withAttributes: fontAttributes)
		
		return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
	}
}
