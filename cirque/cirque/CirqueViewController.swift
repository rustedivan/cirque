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
	var scoreView: ScoreView?
	
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
		    circleController.addSegment(touch.locationInView(view))
		}
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent _: UIEvent?) {
		guard let touch = touches.first else { return }
		
		let result = circleController.endCircle(touch.locationInView(view))
		
		switch result {
		case .Accepted(let score, _):
			showScore(Int(score * 100))
		case .Rejected:
			errorLabel.text = "Rejected"
		}
	}
	
	func render() {
		if scoreView != nil {
			scoreView!.update()
		}
		
		cirqueView.render(circleController.circle, withThickness: 4.0)
	}
	
	func showScore(score: Int) {
		scoreView = ScoreView(frame: CGRect(x: 10.0, y: 10.0, width: 100.0, height: 100.0), score: score)
		scoreView!.update()
		view.addSubview(scoreView!)
	}
}
