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
		
		circleController.endCircle(touch.locationInView(view)) { (result: CircleResult) in
			// Ignore if the circle isn't even a triangle
			guard self.circleController.circle.segments.points.count >= 3 else { return }
			
			dispatch_async(dispatch_get_main_queue(), { 
				switch result {
				case .Accepted(let score, _, let fit):
					self.showScore(Int(score * 100), at: fit.center)
				case .Rejected(let centroid):
					self.rejectScore(at: centroid)
				}
			})
		}
	}
	
	func render() {
		if scoreView != nil {
			scoreView!.update()
		}
		
		cirqueView.render(circleController.circle)
	}
	
	func showScore(score: Int, at: CGPoint) {
		scoreView = ScoreView(frame: CGRect(x: at.x - 50.0, y: at.y - 50.0, width: 100.0, height: 100.0), score: score)
		scoreView!.update()
		view.addSubview(scoreView!)
	}
	
	func rejectScore(at at: CGPoint) {
		scoreView = ScoreView(frame: CGRect(x: at.x - 50.0, y: at.y - 50.0, width: 100.0, height: 100.0), score: 0)
		scoreView!.update()
		view.addSubview(scoreView!)
	}
}
