//
//  CirqueViewController.swift
//  cirque
//
//  Created by Ivan Milles on 24/01/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit

class CirqueViewController: UIViewController {
	var renderingLink: CADisplayLink!
	var circleController: CircleController!
	
	@IBOutlet var errorLabel: UILabel!
	
	var cirqueView: CirqueView {
		return view as! CirqueView
	}
	
	override func viewDidLoad() {
		circleController = CircleController()
		
		renderingLink = CADisplayLink(target: self, selector: #selector(CirqueViewController.render))
		renderingLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
	}

	override func touchesBegan(touches: Set<UITouch>, withEvent _: UIEvent?) {
		guard let touch = touches.first else { return }
		errorLabel.text = ""
		circleController = CircleController()
		circleController.beginNewCircle(touch.locationInView(view))
	}
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		guard let touch = touches.first else { return }
		if #available(iOS 9.0, *) {
		    for extraTouch in event!.coalescedTouchesForTouch(touch)! {
    			circleController.addSegment(extraTouch.locationInView(view))
    		}
		} else {
		    // Fallback on earlier versions
		}
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
	}
	
	func render() {
		cirqueView.render(circleController.circle, withThickness: 4.0)
	}
}
