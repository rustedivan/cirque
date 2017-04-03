//
//  AnalysisController.swift
//  cirque
//
//  Created by Ivan Milles on 2017-04-03.
//  Copyright © 2017 Rusted. All rights reserved.
//

import Foundation

let analysisQueue = DispatchQueue(label: "se.rusted.cirque.analysis", attributes: [])

enum CircleResult {
	case accepted (fit: CircleFit, polar: [Polar], analysis: TrailAnalysis)
	case rejected (centroid: Point)
}

class AnalysisController {
	var analysisRunning = false
	
	func analyseTrail(trail: Trail, after: @escaping (CircleResult) -> ()) {
		analysisQueue.async {
			let (polar, analysis) = self.fitJob(trail)
			
			print(analysis)
			
			let result: CircleResult
			if analysis.isCircle {
				result = .accepted(fit: analysis.circleFit, polar: polar, analysis: analysis)
			} else {
				result = .rejected(centroid: analysis.circleFit.center)
			}
			after(result)
		}
	}
	
	func buildBestCircle(_ polar: [Polar], _ fit: CircleFit, _ clockwise: Bool) -> BestFitCircle {
		let tapering = Taper(taperRatio: 0.2, clockwise: clockwise)
		return BestFitCircle(fit: fit,
												 startAngle: polar.first?.a ?? 0.0,
		                     progress: 1.0,
		                     taper: tapering)
	}
	
	func buildErrorArea(_ polar: [Polar], _ fit: CircleFit) -> ErrorArea {
		return ErrorArea(polar, fit: fit, treshold: 2.0)
	}
	
	func selectBestHint() -> HintType? {
		return .radialDeviation(offset: 0.0, angle: 0.0)
	}
	
	func fitJob(_ trail: Trail) -> ([Polar], TrailAnalysis) {
		let analysis = TrailAnalyser(trail: trail, bucketCount: 36).runAnalysis()
		let polar = polarize(trail, around: analysis.circleFit.center)
		return (polar, analysis)
	}
}
