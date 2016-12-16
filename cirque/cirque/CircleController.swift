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
	case rejected (centroid: Point)
	case accepted (score: Double, trend: Double, fit: BestFitCircle, errorArea: ErrorArea)
}

class CircleController: NSObject {
	var circle: Circle = Circle()

	var analysisTimestamp = Date()
	var analysisRunning = false
	let analysisQueue = DispatchQueue(label: "se.rusted.cirque.analysis", attributes: [])
		
	func beginNewCircle(_ p: Point) {
		circle.begin()
		circle.addSegment(p)
	}
	
	func addSegment(_ p: Point) {
		let distanceFromLastSegment = circle.distanceFromEnd(p)
		if distanceFromLastSegment < circle.segmentFilterDistance {
			return
		}
		
		circle.addSegment(p)
	}

	func endCircle(_ p: Point, after: @escaping (CircleResult) -> ()) {
		circle.addSegment(p)
		circle.end()
		
//		circle.dumpAsSwiftArray()
		
		fitCircle(circle.segments) { (fit: CircleFit) in
			self.analysisTimestamp = Date()
			
			let polar = polarize(self.circle.segments.points, around: fit.center)
			
			let analyser = TrailAnalyser(points: polar, fitRadius: fit.radius)
			
			let isCircle = analyser.isCircle()
			var trend = 0.0
			if isCircle {
				let historyWriter = TrailHistory(filename: "game-trail-history.trails")
				historyWriter.addAnalysis(analyser)
				trend = historyWriter.circularityScoreProgression()
				historyWriter.save()
				historyWriter.dumpScoreHistory()
				
				let score = analyser.circularityScore()
				let errorArea = Circle.generateErrorArea(polar, around: fit.center, radius: fit.radius, treshold: 2.0)
				let t = Taper(taperRatio: 0.2, clockwise: false)
				let bestFitCircle = Circle.generateBestFitCircle(around: fit.center, radius: fit.radius, startAngle: 0.0, progress: 1.0, taper: t)
				
				after(.accepted(score: score, trend: trend, fit: bestFitCircle, errorArea: errorArea))
			}
			else {
				after(.rejected(centroid: fit.center))
			}
		}
	}

	func fitCircle(_ trail: Trail, cb: @escaping CircleFitCallback) {
		if analysisRunning {return}

		analysisRunning = true

		// Messy, so that unit tests can mock out the dispatch
		dispatchFitJob(trail) { (fit: CircleFit) in
			cb(fit)
			self.analysisRunning = false
		}
	}
	
	func dispatchFitJob(_ trail: Trail, cb: @escaping CircleFitCallback) {
		let points = trail.points	// Make copy
		analysisQueue.async {
			cb(CircleFitter.fitCenterAndRadius(points))
		}
	}
}
