//
//  CirqueViewController.swift
//  cirque
//
//  Created by Ivan Milles on 24/01/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit

class CirqueViewController: UIViewController {
	@IBOutlet var errorLabel: UILabel!
	@IBOutlet var circleController: CircleController!
	
	var cirqueView: CirqueView {
		return view as! CirqueView
	}

	override func touchesBegan(touches: Set<UITouch>, withEvent _: UIEvent?) {
		guard let touch = touches.first else { return }
		
		errorLabel.text = ""
		circleController = CircleController()
		circleController.beginNewCircle(touch.locationInView(view))
	}
	
	override func touchesMoved(touches: Set<UITouch>, withEvent _: UIEvent?) {
		guard let touch = touches.first else { return }
		circleController.addSegment(touch.locationInView(view))
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent _: UIEvent?) {
		guard let touch = touches.first else { return }
		
		let result = circleController.endCircle(touch.locationInView(view))
		switch result {
		case .Accepted(let score, let trend):
			errorLabel.text = "Score \(score * 100.0) (trend: \(trend * 10000.0))"
		case .Rejected:
			errorLabel.text = "Rejected"
		}
		
		cirqueView.render(circleController.circle)
	}
}
