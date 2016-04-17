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

	func endCircle(p: CGPoint) -> CircleResult {
		circle.addSegment(p)
		circle.end()
		
//		circle.dumpAsSwiftArray()
		
		// FIXME: doing two analyses :(
		fitCircle(circle.segments) {(fit: CircleFit?) in
			self.bestFit = fit
			self.analysisTimestamp = NSDate()
		}
		
		if let fit = CircleFitter().fitCenterAndRadius(circle.segments.points) {
			let polar = circle.polarizePoints(circle.segments.points, around: fit.center)
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
				return .Accepted(score: score, trend: trend, fit: fit)
			}
		}
		
		let centroid = CircleFitter().calculateCentroid(circle.segments.points)
		return .Rejected(centroid: centroid)
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
