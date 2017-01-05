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
	case accepted (score: Double, trend: Double, fit: BestFitCircle, errorArea: ErrorArea, hint: HintType?)
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
		
		analyseTrail(trail) { (polar: [Polar], analysis: TrailAnalysis) in
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
				let errorArea = ErrorArea(polar, fit: analysis.circleFit, treshold: 2.0)
				let t = Taper(taperRatio: 0.2, clockwise: analysis.isClockwise)
				let bestFitCircle = BestFitCircle(fit: analysis.circleFit, startAngle: polar.first?.a ?? 0.0, progress: 1.0, taper: t)
				
				let hint: HintType? = .radialDeviation(offset: 0.0, angle: 0.0)
				
				after(.accepted(score: score,
				                trend: trend,
				                fit: bestFitCircle,
				                errorArea: errorArea,
				                hint: hint))
			}
			else {
				after(.rejected(centroid: analysis.circleFit.center))
			}
		}
	}

	func analyseTrail(_ trail: Trail, cb: @escaping ([Polar], TrailAnalysis) -> ()) {
		if analysisRunning { return } // FIXME: block with states instead

		analysisRunning = true
		// FIXME: just pass cb directly to dFJ
		// Messy, so that unit tests can mock out the dispatch
		dispatchFitJob(trail) { (analysis, hint) in
			cb(analysis, hint)
			self.analysisRunning = false
		}
	}
	
	func dispatchFitJob(_ trail: Trail, cb: @escaping (([Polar], TrailAnalysis) -> ())) {
		analysisQueue.async {
			let analysis = TrailAnalyser(trail: trail, bucketCount: 36).runAnalysis()
			let polar = polarize(trail, around: analysis.circleFit.center)
			cb(polar, analysis)
		}
	}
}
