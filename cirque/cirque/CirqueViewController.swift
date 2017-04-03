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
	let historyWriter = TrailHistory(filename: "game-trail-history.trails")
	let analysisController = AnalysisController()
	var stateMachine: StateMachine = StateMachine(startState: .idle)
	
	@IBOutlet var scoreView: ScoreView!
	@IBOutlet var analysisView: AnalysisView!

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
		
		let data = DrawingData(trail: circleController.trail)
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
		
		let data = DrawingData(trail: circleController.trail)
		stateMachine.currentState = .drawing(data)
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
		guard let touch = touches.first else { return }
		
		let p = touch.location(in: view)
		let trail = circleController.endCircle(Point(x: Double(p.x), y: Double(p.y)))
		
		// TODO: block input while running
		analysisController.analyseTrail(trail: trail) { result in
			// Ignore if the circle isn't even a triangle
			guard self.circleController.trail.count >= 3 else { return }
			
			// Present back on the UI thread
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
		case .hinting:
			cirqueView.render(renderState: state)
			analysisView.setNeedsDisplay()
		}
	}
	
	func renderStateTransition(from old: State, to new: State) {
		switch (old, new) {
		case (_, .scoring(let data)):
			showScore(data.score, at: data.showAt)
		case (_, .rejecting(let data)):
			rejectScore(at: data.showAt)
		case (_, .hinting(let data)):
			showHint(bestFit: data.bestCircle, hint: data.hint)
		case (.hinting, _):
			hideHint()
		default: break
		}
	}
	
	func presentResult(_ result: CircleResult) {
		
		switch result {
		case .accepted(let fit, let polar, let analysis):
			let bestCircle = analysisController.buildBestCircle(polar, fit, analysis.isClockwise)
			let errorArea = analysisController.buildErrorArea(polar, fit)
			let hint = analysisController.selectBestHint()
			
			// Show analysis
			let data = AnalysingData(trail: circleController.trail,
			                         bestCircle: bestCircle,
			                         errorArea: errorArea)
			stateMachine.currentState = .analysing(data)
			
			animateAnalysis(showScore: analysis.circularityScore, bestFit: bestCircle, withHint: hint)
		case .rejected(let centroid):
			// Show rejection immediately
			let data = RejectingData(trail: circleController.trail, showAt: centroid)
			stateMachine.currentState = .rejecting(data)
		}
	}
	
	func animateAnalysis(showScore score: Double, bestFit: BestFitCircle, withHint hint: HintType?) {
		// Enqueue score countup
		// TODO: Put on duration queue
		let startScoreCountupAt = DispatchTime.now() + .milliseconds(3000)
		DispatchQueue.main.asyncAfter(deadline: startScoreCountupAt) {
			let data = ScoringData(trail: self.circleController.trail,
			                       showAt: bestFit.fit.center,
			                       score: score)
			self.stateMachine.currentState = .scoring(data)
		}
		
		// Optionally enqueue hint display
		guard let hint = hint else { return }
		let startHintingAt = DispatchTime.now() + .milliseconds(4500)
		DispatchQueue.main.asyncAfter(deadline: startHintingAt) {
			let data = HintingData(trail: self.circleController.trail,
			                       bestCircle: bestFit,
			                       hint: hint)
			self.stateMachine.currentState = .hinting(data)
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
	
	func showHint(bestFit: BestFitCircle, hint: HintType) {
		analysisView.isHidden = false
		if case .radialDeviation(let hintData) = hint {
			analysisView.presentAnalysis(showAt: bestFit.fit.center,
			                             radius: bestFit.fit.radius + hintData.offset,
			                             angle: hintData.angle)
		}
	}
	
	func hideHint() {
		analysisView.isHidden = true
	}
}
