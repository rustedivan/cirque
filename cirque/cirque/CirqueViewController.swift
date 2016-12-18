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
	@IBOutlet var scoreView: ScoreView!
	
	var renderState: RenderWorld = .idle {
		willSet {
			renderStateTransition(from: renderState, to: newValue)
		}
	}
	
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
		circleController = CircleController()
		let p = touch.location(in: view)
		circleController.beginNewCircle(Point(x: Double(p.x), y: Double(p.y)))
		
		renderState = .drawing(circle: circleController.circle)
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
		
		renderState = .drawing(circle: circleController.circle)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
		guard let touch = touches.first else { return }
		
		let p = touch.location(in: view)
		circleController.endCircle(Point(x: Double(p.x), y: Double(p.y))) { (result: CircleResult) in
			// Ignore if the circle isn't even a triangle
			guard self.circleController.circle.segments.points.count >= 3 else { return }
			
			DispatchQueue.main.async {
				self.presentResult(result)
			}
		}
	}
	
	func render() {
		switch renderState {
		case .idle:
			cirqueView.backgroundColor = .gray
			cirqueView.render(renderState: renderState)
		case .drawing:
			cirqueView.backgroundColor = .white
			cirqueView.render(renderState: renderState)
		case .analysis:
			cirqueView.backgroundColor = .cyan
			cirqueView.render(renderState: renderState)
		case .rejection:
			cirqueView.backgroundColor = .red
			cirqueView.render(renderState: renderState)
			scoreView.setNeedsDisplay()
		case .scoring:
			cirqueView.backgroundColor = .green
			cirqueView.render(renderState: renderState)
			scoreView.setNeedsDisplay()
		}
	}
	
	func renderStateTransition(from old: RenderWorld, to new: RenderWorld) {
		switch (old, new) {
		case (_, .scoring(_, let showAt, let score)):
			showScore(score, at: showAt)
		case (_, .rejection(_, let showAt)):
			rejectScore(at: showAt)
		default: break
		}
	}
	
	func presentResult(_ result: CircleResult) {
		switch result {
			
		case .accepted(let score, _, let fit, let errorArea):
			// Show analysis
			renderState = .analysis(circle: circleController.circle,
			                        fit: fit,
															errorArea: errorArea)
			
			// Enqueue score countup
			let startScoreCountupAt = DispatchTime.now() + .milliseconds(1500)
			DispatchQueue.main.asyncAfter(deadline: startScoreCountupAt) {
				self.renderState = .scoring(circle: self.circleController.circle,
				                            showAt: fit.center,
				                            score: score)
			}
		case .rejected(let centroid):
			// Show rejection immediately
			self.renderState = .rejection(circle: self.circleController.circle,
			                              showAt: centroid)
			
		}
	}
	
	func showScore(_ score: Double, at: Point) {
		scoreView.frame = CGRect(x: at.x - 50.0, y: at.y - 50.0, width: 100.0, height: 100.0)
		scoreView.presentScore(score: score)
	}
	
	func rejectScore(at: Point) {
		scoreView.frame = CGRect(x: at.x - 50.0, y: at.y - 50.0, width: 100.0, height: 100.0)
		scoreView.presentScore(score: 0.0)
	}
}
