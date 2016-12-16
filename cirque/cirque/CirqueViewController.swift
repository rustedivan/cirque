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
		let p = touch.location(in: view)
		circleController.beginNewCircle(Point(x: Double(p.x), y: Double(p.y)))
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		if #available(iOS 9.0, *) {
		    for extraTouch in event!.coalescedTouches(for: touch)! {
					let p = extraTouch.location(in: view)
					circleController.addSegment(Point(x: Double(p.x), y: Double(p.y)))
    		}
		}
		
		let p = touch.location(in: view)
		circleController.addSegment(Point(x: Double(p.x), y: Double(p.y)))
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
		guard let touch = touches.first else { return }
		
		let p = touch.location(in: view)
		circleController.endCircle(Point(x: Double(p.x), y: Double(p.y))) { (result: CircleResult) in
			// Ignore if the circle isn't even a triangle
			guard self.circleController.circle.segments.points.count >= 3 else { return }
			
			DispatchQueue.main.async(execute: { 
				switch result {
				case .accepted(let score, _, let fit, let errorArea):
					self.circleController.errorArea = errorArea
					self.showScore(Int(score * 100), at: CGPoint(point: fit.center))
				case .rejected(let centroid):
					self.rejectScore(at: CGPoint(point: centroid))
				}
			})
		}
	}
	
	func render() {
		if scoreView != nil {
			scoreView!.update()
		}
		
		cirqueView.render(circle: circleController.circle,
		                  errorArea: circleController.errorArea)
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
