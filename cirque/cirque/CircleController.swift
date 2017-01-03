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
		
		analyseTrail(trail) { (fit: CircleFit, analysis: TrailAnalysis, hint: Hint?) in
			self.analysisTimestamp = Date()
			
			var trend = 0.0
			if analysis.isCircle {
				let historyWriter = TrailHistory(filename: "game-trail-history.trails")
				historyWriter.addAnalysis(analysis)
				trend = historyWriter.circularityScoreProgression()
				historyWriter.save()
//				historyWriter.dumpScoreHistory()
				
				print(analysis)
				
				let score = analysis.circularityScore
				let errorArea = ErrorArea(polar, around: fit.center, radius: fit.radius, treshold: 2.0)
				let t = Taper(taperRatio: 0.2, clockwise: analyser.isClockwise())
				let bestFitCircle = BestFitCircle(around: fit.center, radius: fit.radius, startAngle: polar.first?.a ?? 0.0, progress: 1.0, taper: t)
				
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

	func analyseTrail(_ trail: Trail, cb: @escaping (CircleFit, TrailAnalysis) -> ()) {
		if analysisRunning { return } // FIXME: block with states instead

		analysisRunning = true

		// Messy, so that unit tests can mock out the dispatch
		dispatchFitJob(trail) { (fit: CircleFit, analysis: TrailAnalysis) in
			cb(fit, analysis)
			self.analysisRunning = false
		}
	}
	
	func dispatchFitJob(_ trail: Trail, cb: @escaping ((CircleFit, TrailAnalysis, Hint?) -> ())) {
		analysisQueue.async {
			TrailAnalyser.fitCenterAndRadius(trail)
			cb()
		}
	}
}
