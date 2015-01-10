//
//  CircleController.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

class CircleController: NSObject {
	var circle: Circle = Circle()
	var bestFit: CircleFit?

	var analysisTimestamp = NSDate()
	var analysisRunning = false
	let analysisQueue = dispatch_queue_create("se.rusted.cirque.analysis", nil)
	
	func draw(view: CircleView) {
		view.render(circle)
		if let fit = bestFit {
			view.renderFitWithRadius(fit.radius, at: fit.center)
		}
	}
	
	func beginNewCircle(p: CGPoint) {
		circle.begin()
		circle.addSegment(p)
	}
	
	func addSegment(p: CGPoint) {
		let distanceFromLastSegment = circle.distanceFromEnd(p)
		if distanceFromLastSegment < circle.segmentFilterDistance {
			return
		}
		
		circle.addSegment(p)
		
		if NSDate().timeIntervalSinceDate(analysisTimestamp) > 0.2 {
			fitCircle(circle.segments) {(fit: CircleFit?) in
				self.bestFit = fit
				self.analysisTimestamp = NSDate()
			}
		}
	}

	// FIXME: find a better return mechanism than dictionary. Tuple.
	func endCircle(p: CGPoint) -> Dictionary<String, AnyObject> {
		circle.addSegment(p)
		circle.end()
		
//		circle.dumpAsSwiftArray()
		
		if let fit = CircleFitter().fitCenterAndRadius(circle.segments.points) {
			let polar = circle.polarizePoints(circle.segments.points, around: fit.center)
			let analyser = TrailAnalyser(points: polar, fitRadius: Double(fit.radius))
			
			let score = analyser.circularityScore()
			return ["valid" : analyser.isCircle(), "score" : score]
		} else {
			return ["valid" : false]
		}
	}

	func fitCircle(trail: Trail, cb: CircleFitCallback) {
		if analysisRunning {return}

		analysisRunning = true

		// Messy, so that unit tests can mock out the dispatch
		dispatchFitJob(trail) { (fit: CircleFit?) in
			cb(fit)
			self.analysisRunning = false
		}
	}
	
	func dispatchFitJob(trail: Trail, cb: CircleFitCallback) {
		let points = trail.points	// Make copy
		dispatch_async(analysisQueue) {
			let fit = CircleFitter().fitCenterAndRadius(points)
			cb(fit)
		}
	}
}
