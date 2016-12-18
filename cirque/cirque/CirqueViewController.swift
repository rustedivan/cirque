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
			transitionRenderState(from: renderState, to: newValue)
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
			
			DispatchQueue.main.async(execute: { 
				switch result {
				case .accepted(let score, _, let fit, let errorArea):
					self.renderState = .analysis(circle: self.circleController.circle,
					                             fit: fit,
					                             errorArea: errorArea)
//					self.showScore(Int(score * 100), at: CGPoint(point: fit.center))
				case .rejected(let centroid):
					self.renderState = .rejection(circle: self.circleController.circle,
					                              center: centroid)
//					self.rejectScore(at: CGPoint(point: centroid))
				}
			})
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
		case .scoring:
			scoreView.update()
			cirqueView.backgroundColor = .green
			cirqueView.render(renderState: renderState)
		}
	}
	
	func transitionRenderState(from: RenderWorld, to: RenderWorld) {
		switch (from: from, to: to) {
		case (_, .scoring):
			print("Show scoring")
		case (.scoring, _):
			print("Hide scoring")
		default: break
		}
	}
	
	// FIXME: keep score view onscreen at all times, just make it show nothing
	func showScore(_ score: Int, at: CGPoint) {
		scoreView.frame = CGRect(x: at.x - 50.0, y: at.y - 50.0, width: 100.0, height: 100.0)
		scoreView.presentScore(score: score)
	}
	
	func rejectScore(at: CGPoint) {
		scoreView.frame = CGRect(x: at.x - 50.0, y: at.y - 50.0, width: 100.0, height: 100.0)
		scoreView.presentScore(score: 0.0)
	}
}
