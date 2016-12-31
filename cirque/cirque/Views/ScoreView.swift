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
		let score: Double
		let displayStartTime: Date
		let countUpStartTime: Date
		
		func scoreString(atTime time: Date, countDuration duration: Double) -> String {
			guard score > DBL_EPSILON else { return "X" }
			
			let displayedDuration = time.timeIntervalSince(countUpStartTime)
			
			let percentFormatter = NumberFormatter()
			percentFormatter.numberStyle = .percent
			percentFormatter.minimumFractionDigits = 0
			percentFormatter.maximumFractionDigits = 0
			
			let progress = displayedDuration / duration
			let displayedScore = score * min(progress, 1.0)
			
			return percentFormatter.string(from: NSNumber(value: displayedScore)) ?? ""
		}
	}
	
	private static let displayDuration = 1.5
	private static let countupDuration = 0.5
	
	var viewModel = ViewModel(score: 0.0, displayStartTime: .distantPast, countUpStartTime: .distantPast)
	
	override func draw(_ rect: CGRect) {
		if Date().timeIntervalSince(viewModel.displayStartTime) < ScoreView.displayDuration {
			let scoreString = viewModel.scoreString(atTime: Date(), countDuration: ScoreView.countupDuration)
			let scoreImage = percentageAsImage(scoreString, imageWidth: rect.width)
			let center = Point(x: Double(rect.midX), y: Double(rect.midY))
			let centered = Point(x: center.x - Double(scoreImage.size.width) / 2.0, y: center.y - Double(scoreImage.size.height) / 2.0)
			let scoreRect = CGRect(origin: CGPoint(x: centered.x, y: centered.y), size: scoreImage.size)
			
			scoreImage.draw(in: scoreRect)
		}
	}
	
	func presentScore(score: Double) {
		viewModel = ViewModel(score: score,
		                      displayStartTime: Date(),
		                      countUpStartTime: Date())
	}
	
	fileprivate func percentageAsImage(_ percentageString: String, imageWidth: CGFloat) -> UIImage {
		// $ Add test for this
		let fontSize = imageWidth / 2.35	// Linear estimate between image width and this particular font setup
		
		var fontAttributes: [String:AnyObject]
		if #available(iOS 8.2, *) {
			fontAttributes = [
				NSFontAttributeName : UIFont.systemFont(ofSize: fontSize, weight: UIFontWeightLight),
				NSStrokeWidthAttributeName : 0.0 as AnyObject,
				NSForegroundColorAttributeName : UIColor.white
			]
		} else {
			fontAttributes = [
				NSFontAttributeName : UIFont.systemFont(ofSize: fontSize),
				NSStrokeWidthAttributeName : 0.0 as AnyObject,
				NSForegroundColorAttributeName : UIColor.white
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
