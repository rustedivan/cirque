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
		renderingLink.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
	}

	override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
		guard let touch = touches.first else { return }
		errorLabel.text = ""
		circleController = CircleController()
		circleController.beginNewCircle(touch.location(in: view))
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		if #available(iOS 9.0, *) {
		    for extraTouch in event!.coalescedTouches(for: touch)! {
    			circleController.addSegment(extraTouch.location(in: view))
    		}
		} else {
		    circleController.addSegment(touch.location(in: view))
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
		guard let touch = touches.first else { return }
		
		circleController.endCircle(touch.location(in: view)) { (result: CircleResult) in
			// Ignore if the circle isn't even a triangle
			guard self.circleController.circle.segments.points.count >= 3 else { return }
			
			DispatchQueue.main.async(execute: { 
				switch result {
				case .accepted(let score, _, let fit, _):
					self.showScore(Int(score * 100), at: fit.center)
				case .rejected(let centroid):
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
	
	func showScore(_ score: Int, at: CGPoint) {
		scoreView = ScoreView(frame: CGRect(x: at.x - 50.0, y: at.y - 50.0, width: 100.0, height: 100.0), score: score)
		scoreView!.update()
		view.addSubview(scoreView!)
	}
	
	func rejectScore(at: CGPoint) {
		scoreView = ScoreView(frame: CGRect(x: at.x - 50.0, y: at.y - 50.0, width: 100.0, height: 100.0), score: 0)
		scoreView!.update()
		view.addSubview(scoreView!)
	}
}
