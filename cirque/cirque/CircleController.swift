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
	case accepted (score: Double, trend: Double, fit: CircleFit, errorArea: ErrorArea)
}

class CircleController: NSObject {
	var circle: Circle = Circle()
	var bestFit: CircleFit?
	var errorArea: ErrorArea = ErrorArea(polarPoints: [], center: .zero)

	var analysisTimestamp = Date()
	var analysisRunning = false
	let analysisQueue = DispatchQueue(label: "se.rusted.cirque.analysis", attributes: [])
		
	func beginNewCircle(_ p: CGPoint) {
		circle.begin()
		circle.addSegment(p)
	}
	
	func addSegment(_ p: CGPoint) {
		let distanceFromLastSegment = circle.distanceFromEnd(p)
		if distanceFromLastSegment < circle.segmentFilterDistance {
			return
		}
		
		circle.addSegment(p)
		
	}

	func endCircle(_ p: CGPoint, after: @escaping (CircleResult) -> ()) {
		circle.addSegment(p)
		circle.end()
		
//		circle.dumpAsSwiftArray()
		
		fitCircle(circle.segments) { (fit: CircleFit) in
			self.bestFit = fit
			self.analysisTimestamp = Date()
			
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
				self.errorArea = self.circle.generateErrorArea(polar, around: fit.center, radius: fit.radius, treshold: 2.0)
				after(.accepted(score: score, trend: trend, fit: fit, errorArea: self.errorArea))
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
