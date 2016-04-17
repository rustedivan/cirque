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
		var scoreString: String
	}
	
	var countUpStartTime: NSDate!
	var viewModel = ViewModel(scoreString: "")
	var targetScore: Int = 0
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	convenience init(frame: CGRect, score: Int) {
		self.init(frame: frame)
		self.countUpStartTime = NSDate()
		self.targetScore = score
		self.backgroundColor = UIColor.clearColor()
		self.opaque = false
	}
	
	override func drawRect(rect: CGRect) {
		let scoreImage = percentageAsImage(viewModel.scoreString, imageWidth: rect.width)
		let center = CGPoint(x: CGRectGetMidX(rect), y: CGRectGetMidY(rect))
		let centered = CGPoint(x: center.x - scoreImage.size.width / 2.0, y: center.y - scoreImage.size.height / 2.0)
		let scoreRect = CGRect(origin: centered, size: scoreImage.size)
		
		scoreImage.drawInRect(scoreRect)
	}
	
	func update() {
		viewModel.scoreString = "\(targetScore)%"
		if (NSDate().timeIntervalSinceDate(countUpStartTime) > 1.0) {
			removeFromSuperview()
		}
		else {
			setNeedsDisplay()
		}
	}
	
	func percentageAsImage(percentageString: String, imageWidth: CGFloat) -> UIImage {
		// $ Add test for this
		let fontSize = imageWidth / 2.35	// Linear estimate between image width and this particular font setup
		
		var fontAttributes: [String:AnyObject]
		if #available(iOS 8.2, *) {
			fontAttributes = [
				NSFontAttributeName : UIFont.systemFontOfSize(fontSize, weight: UIFontWeightLight),
				NSStrokeWidthAttributeName : 0.0,
				NSForegroundColorAttributeName : UIColor.blueColor()
			]
		} else {
			fontAttributes = [
				NSFontAttributeName : UIFont.systemFontOfSize(fontSize),
				NSStrokeWidthAttributeName : 0.0,
				NSForegroundColorAttributeName : UIColor.blueColor()
			]
		}
		
		let string = NSString(string: percentageString)
		let size = string.sizeWithAttributes(fontAttributes)
		
		UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
		defer { UIGraphicsEndImageContext() }
		
		string.drawAtPoint(CGPointZero, withAttributes: fontAttributes)
		
		return UIGraphicsGetImageFromCurrentImageContext()
	}
}