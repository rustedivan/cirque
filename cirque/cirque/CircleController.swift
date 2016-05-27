//
//  CircleController.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

enum CircleResult {
	case Rejected (centroid: Point)
	case Accepted (score: Double, trend: Double, fit: CircleFit)
}

class CircleController: NSObject {
	var circle: Circle = Circle()
	var bestFit: CircleFit?

	var analysisTimestamp = NSDate()
	var analysisRunning = false
	let analysisQueue = dispatch_queue_create("se.rusted.cirque.analysis", nil)
		
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
		
	}

	func endCircle(p: CGPoint, after: (CircleResult) -> ()) {
		circle.addSegment(p)
		circle.end()
		
//		circle.dumpAsSwiftArray()
		
		fitCircle(circle.segments) { (fit: CircleFit) in
			self.bestFit = fit
			self.analysisTimestamp = NSDate()
			
			let polar = polarize(self.circle.segments.points, around: fit.center)
			let analyser = TrailAnalyser(points: polar, fitRadius: Double(fit.radius))
			
			let isCircle = analyser.isCircle()
			var trend = 0.0
			if isCircle {
				let historyWriter = TrailHistory(filename: "game-trail-history.trails")
				historyWriter.addAnalysis(analyser)
				trend = historyWriter.circularityScoreProgression()
				historyWriter.save()
				historyWriter.dumpScoreHistory()
				
				let score = analyser.circularityScore()
				after(.Accepted(score: score, trend: trend, fit: fit))
			}
			else {
				after(.Rejected(centroid: fit.center))
			}
		}
	}

	func fitCircle(trail: Trail, cb: CircleFitCallback) {
		if analysisRunning {return}

		analysisRunning = true

		// Messy, so that unit tests can mock out the dispatch
		dispatchFitJob(trail) { (fit: CircleFit) in
			cb(fit)
			self.analysisRunning = false
		}
	}
	
	func dispatchFitJob(trail: Trail, cb: CircleFitCallback) {
		let points = trail.points	// Make copy
		dispatch_async(analysisQueue) {
			cb(CircleFitter.fitCenterAndRadius(points))
		}
	}
}
