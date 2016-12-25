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
	
	var stateMachine: StateMachine = StateMachine(startState: .idle)
	
	var cirqueView: CirqueView {
		return view as! CirqueView
	}
	
	override func viewDidLoad() {
		circleController = CircleController()
		renderingLink = CADisplayLink(target: self, selector: #selector(CirqueViewController.render))
		renderingLink.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
		
		stateMachine.onStateChange = { (from, to) in
			self.renderStateTransition(from: from, to: to)
		}
	}

	override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
		guard let touch = touches.first else { return }
		circleController = CircleController()
		let p = touch.location(in: view)
		circleController.beginNewCircle(Point(x: Double(p.x), y: Double(p.y)))
		
		let data = DrawingData(circle: circleController.circle)
		stateMachine.currentState = .drawing(data)
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
		
		let data = DrawingData(circle: circleController.circle)
		stateMachine.currentState = .drawing(data)
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
		cirqueView.backgroundColor = RenderStyle.backgroundColor
		
		let state = stateMachine.currentState
		switch state {
		case .idle:
			cirqueView.render(renderState: state)
		case .drawing:
			cirqueView.render(renderState: state)
		case .analysing:
			cirqueView.render(renderState: state)
		case .rejecting:
			cirqueView.render(renderState: state)
			scoreView.setNeedsDisplay()
		case .scoring:
			cirqueView.render(renderState: state)
			scoreView.setNeedsDisplay()
		}
	}
	
	func renderStateTransition(from old: State, to new: State) {
		switch (old, new) {
		case (_, .scoring(let data)):
			showScore(data.score, at: data.showAt)
		case (_, .rejecting(let data)):
			rejectScore(at: data.showAt)
		default: break
		}
	}
	
	func presentResult(_ result: CircleResult) {
		switch result {
			
		case .accepted(let score, _, let fit, let errorArea):
			// Show analysis
			let data = AnalysingData(circle: circleController.circle, fit: fit, errorArea: errorArea)
			
			stateMachine.currentState = .analysing(data)
			
			// Enqueue score countup
			let startScoreCountupAt = DispatchTime.now() + .milliseconds(1500)
			DispatchQueue.main.asyncAfter(deadline: startScoreCountupAt) {
				let data = ScoringData(circle: self.circleController.circle, showAt: fit.center, score: score)
				self.stateMachine.currentState = .scoring(data)
			}
		case .rejected(let centroid):
			// Show rejection immediately
			let data = RejectingData(circle: circleController.circle, showAt: centroid)
			stateMachine.currentState = .rejecting(data)
			
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
