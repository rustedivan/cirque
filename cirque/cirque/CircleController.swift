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
	case accepted (score: Double, trend: Double, fit: BestFitCircle, errorArea: ErrorArea, hint: HintType)
}

class CircleController {
	var trail = Trail()

	var analysisTimestamp = Date()
	var analysisRunning = false
	let analysisQueue = DispatchQueue(label: "se.rusted.cirque.analysis", attributes: [])
		
	func beginNewCircle(_ p: Point) {
		trail.addPoint(p)
	}
	
	func addSegment(_ p: Point) {
		guard trail.distanceFromEnd(p) > Trail.segmentFilterDistance else {
			return
		}
		
		trail.addPoint(p)
	}

	func endCircle(_ p: Point, after: @escaping (CircleResult) -> ()) {
		trail.addPoint(p)
		
//		circle.dumpAsSwiftArray()
		
		fitCircle(trail) { (fit: CircleFit) in
			self.analysisTimestamp = Date()
			
			let polar = polarize(self.trail, around: fit.center)
			
			let analyser = TrailAnalyser(points: polar, fitRadius: fit.radius, bucketCount: 36)
			
			let isCircle = analyser.isCircle()
			var trend = 0.0
			if isCircle {
				let historyWriter = TrailHistory(filename: "game-trail-history.trails")
				historyWriter.addAnalysis(analyser)
				trend = historyWriter.circularityScoreProgression()
				historyWriter.save()
//				historyWriter.dumpScoreHistory()
				
				analyser.dumpFullAnalysis()
				
				let score = analyser.circularityScore()
				let errorArea = ErrorArea(polar, around: fit.center, radius: fit.radius, treshold: 2.0)
				let t = Taper(taperRatio: 0.2, clockwise: analyser.isClockwise())
				let bestFitCircle = BestFitCircle(around: fit.center, radius: fit.radius, startAngle: polar.first?.a ?? 0.0, progress: 1.0, taper: t)
				
				let hint = analyser.bestHint
				after(.accepted(score: score,
				                trend: trend,
				                fit: bestFitCircle,
				                errorArea: errorArea,
				                hint: hint))
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
		analysisQueue.async {
			cb(CircleFitter.fitCenterAndRadius(trail))
		}
	}
}
