//
//  TrailAnalyser.swift
//  cirque
//
//  Created by Ivan Milles on 30/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation

/* 
	Insight: - for scoring, only radial displacement counts. Put that on an exponential curve and report it verbatim.
					 - for hinting, if the radial peak is in the last 20%:
						 - end caps separation if > X
						 - end slope if > X
					 - for hinting, if the radial peak is elsewhere, point
						 it out with contract/expand info according to the time
						 series of the historical error on a exponential decay
						 window stretching back ~20-30 circles.
*/

struct TrailAnalysis: Equatable, CustomDebugStringConvertible {
	let circleFit: CircleFit
	let isClockwise: Bool
	let isComplete: Bool
	let radialFitness: Double
	let radialContraction: Double
	let endCapsSeparation: Double
	let strokeEvenness: Double
	let radialDeviation: (peak: Double, angle: Double)
	let strokeCongestion: (peak: Double, angle: Double)
	
	/*	Grade the radial deviations on a reverse quadratic curve.
			Approved radial fitnesses lie on 0.0...0.1, so scale that up
			by a factor of 10 and clamp it to normalize. Reverse and square.
	*/
	var circularityScore: Double {
		let errorInterval = 0.0...1.0
		let errorScale = 10.0
		let scaledError = radialFitness * errorScale
		let lowerBound = min(scaledError, errorInterval.upperBound)
		let error = max(lowerBound, errorInterval.lowerBound)
		let score = error - (errorInterval.upperBound - errorInterval.lowerBound)
		let gradedScore = score * score
		return gradedScore
	}
	
	var isCircle: Bool {
		// Circle must be closed
		let endCapErrorThreshold = circleFit.radius / 2.0	// Caps are off by half the radius
		if (endCapsSeparation > endCapErrorThreshold) {
			print("Rejected end caps: \(endCapsSeparation) > \(endCapErrorThreshold)")
			return false
		}
		
		// Circle must be round
		// Threshold value of 11% is determined via experimentation.
		let radialErrorThreshold = 0.11
		if (radialFitness > radialErrorThreshold) {
			print("Rejected roundness: \(radialFitness) > \(radialErrorThreshold)")
			return false
		}
		
		if isComplete == false {
			print("Rejected completeness: most point buckets are empty")
			return false
		}
		
		return true
	}
	
	static func ==(lhs: TrailAnalysis, rhs: TrailAnalysis) -> Bool {
		if lhs.isClockwise != rhs.isClockwise { return false }
		if lhs.radialFitness != rhs.radialFitness { return false }
		if lhs.radialContraction != rhs.radialContraction { return false }
		if lhs.endCapsSeparation != rhs.endCapsSeparation { return false }
		if lhs.strokeEvenness != rhs.strokeEvenness { return false }
		if lhs.radialDeviation != rhs.radialDeviation { return false }
		if lhs.strokeCongestion != rhs.strokeCongestion { return false }
		
		return true
	}
	
	var debugDescription : String {
		var out = "Accepted circle:"
		out += "\n\tDirection:        \(isClockwise ? "clockwise" : "counter-clockwise")"
		out += "\n\tCircularity:"
		out += "\n\t- score:          \(Int(circularityScore * 100.0))%"
		out += "\n\t- radial fitness: \(Int(radialFitness * 100.0))%"
		out += "\n\t- contraction:    \(radialContraction)"
		out += "\n\t- cap separation: \(Int(endCapsSeparation)) pixels"
		out += "\n\tRadial deviation:"
		out += "\n\t- peak:           \(Int(radialDeviation.peak))"
		out += "\n\t- angle:          \(Int((radialDeviation.angle / .pi) * 180.0))º"
		out += "\n\tStroke evenness:"
		out += "\n\t- peak:           \(Int(strokeCongestion.peak))"
		out += "\n\t- angle:          \(Int((strokeCongestion.angle / .pi) * 180.0))º"
		return out
	}
}

class TrailAnalyser {
	let trail: Trail
	let bucketCount: Int
	
	init(trail: Trail, bucketCount: Int) {
		self.trail = trail
		self.bucketCount = bucketCount
	}
	
	func runAnalysis() -> TrailAnalysis {
		let fit = TrailAnalyser.fitCenterAndRadius(trail)
		let polarPoints = polarize(trail, around: fit.center)
		let angleDeltas = angleDistances(polarPoints)
		let pointBuckets = TrailAnalyser.binPointsByAngle(polarPoints, intoBuckets: bucketCount)
		let deviations = deviationsFromFit(points: polarPoints, fromRadius: fit.radius)
		let bucketErrors = TrailAnalyser.calcBucketErrors(pointBuckets: pointBuckets, fromRadius: fit.radius)
		
		return TrailAnalysis(
			circleFit:								fit,
			isClockwise:							isClockwise(angleDeltas: angleDeltas),
			isComplete:								isComplete(pointBuckets: pointBuckets),
			radialFitness:						radialFitness(deviationsFromFit: deviations, fromRadius: fit.radius),
			radialContraction:				radialContraction(points: polarPoints),
			endCapsSeparation:				endCapsSeparation(trail: trail),
			strokeEvenness:						strokeEvenness(angleDeltas: angleDeltas),
			radialDeviation:					radialDeviation(pointBuckets: pointBuckets, bucketErrors: bucketErrors, fromRadius: fit.radius),
			strokeCongestion:					strokeCongestion(pointBuckets: pointBuckets)
		)
	}
	
	class func binPointsByAngle(_ points: [Polar], intoBuckets buckets: Int) -> [AngleBucket] {
		var histogram = [AngleBucket](repeating: ([], 0.0), count: buckets)
		let nBuckets = Double(buckets)
		
		for i in 0..<buckets {
			histogram[i].angle = (2.0 * .pi / nBuckets) * Double(i)
		}
		
		let bucketWidth = 2.0 * .pi / nBuckets
		for p in points {
			let i = Int(p.a / bucketWidth)
			histogram[i].points.append(p)
		}
		return histogram
	}
	
	
}

fileprivate extension TrailAnalyser {
	class func calcBucketErrors(pointBuckets: [AngleBucket], fromRadius radius: Double) -> [Double] {
		// Calculate moving average
		let n = pointBuckets.count
		var bucketErrors = Array<Double>(repeating: 0.0, count: n)
		for i in 0..<n {
			let bucket = pointBuckets[i]
			var bucketError = 0.0
			for p in bucket.points {
				let e = p.r - radius
				bucketError += e * e
			}
			bucketErrors[i] = bucketError
		}
		return bucketErrors
	}
	
	func isClockwise(angleDeltas: [Double]) -> Bool {
		let sumOfArcs = angleDeltas.reduce(0.0, +)
		return sumOfArcs < 0.0
	}
	
	// Circle must be complete - most buckets should have points in them
	func isComplete(pointBuckets: [AngleBucket]) -> Bool {
		let emptyBuckets = pointBuckets.filter { $0.points.isEmpty }.count
		return emptyBuckets < pointBuckets.count / 2
	}
	
	/*	Measure the relative RMS of radial errors, i.e. how round the circle is.
			Given a fitted circle, calculate each point's radial displacement from
			the fit. Find the RMS relative to the size of the circle. */
	func radialFitness(deviationsFromFit deviations: [Double], fromRadius radius: Double) -> Double {
		let errorThreshold = 0.02

		let rmsError = sqrt(deviations.reduce(0.0) {$0 + $1 * $1} / Double(deviations.count))
		let relativeRMS = rmsError / radius
		
		return (relativeRMS > errorThreshold) ? relativeRMS : 0.0
	}
	
	/*	Find area of the stroke where radius diverges from its ideal path.
			Calculate a moving average on the radius samples with a window size of 45º
			around the circle. Report the largest absolute deviation from the mean.
			Report the value and map its center to an angle.
	*/
	func radialDeviation(pointBuckets: [AngleBucket],
	                     bucketErrors: [Double],
	                     fromRadius radius: Double) -> (peak: Double, angle: Double) {
		let errorThreshold = 1.0
		
		// Find largest/smallest value among the buckets
		let n = bucketErrors.count
		var largestValue = -1.0
		var largestIndex = -1
		for i in 0..<n {
			let v = bucketErrors[i]
			if v > largestValue {largestValue = v; largestIndex = i}
		}
		
		// Return the largest value in the "worst" bucket
		let largestBucket = pointBuckets[largestIndex]
		let bucketRadii = largestBucket.points.map({$0.r})
		var peakError = 0.0
		for r in bucketRadii {
			let e = r - radius
			if abs(e) > abs(peakError) {
				peakError = e
			}
		}
		
		return (abs(peakError) > errorThreshold) ? (peak: peakError, angle: pointBuckets[largestIndex].angle) :
																							 (peak: 0.0, angle: 0.0)
	}
	
	/*	Measure difference between radial RMS and beginning and end of the circle.
	A contracting circle will have negative local relative radial RMS; an
	an expanding circle will have a positive LRR-RMS. */
	func radialContraction(points: [Polar]) -> Double {
		let errorThreshold = 2.0
		
		let n = points.count
		let windowSize = n / 20
		let calcRMS = { (points: ArraySlice<Polar>) -> Double in
			sqrt(points.reduce(0.0) { $0 + ($1.r * $1.r) } / Double(n))
		}
		
		let startPoints = points[0 ..< windowSize]
		let endPoints = points[n - windowSize ..< n]
		let startRadius = calcRMS(startPoints)
		let endRadius = calcRMS(endPoints)
		
		let contraction = endRadius - startRadius
		
		return (abs(contraction) > errorThreshold) ? contraction : 0.0
	}
	
	func deviationsFromFit(points: [Polar], fromRadius radius: Double) -> [Double] {
		return points.map { $0.r - radius }
	}
}

fileprivate extension TrailAnalyser {
	func endCapsSeparation(trail: Trail) -> Double {
		guard let firstPoint = trail.first else { return 0.0 }
		guard let lastPoint = trail.last else { return 0.0 }
		let errorThreshold = 10.0
		
		let capsSeparationVector = Vector(dx: lastPoint.x - firstPoint.x, dy: lastPoint.y - firstPoint.y)
		let separation = sqrt(capsSeparationVector.dx * capsSeparationVector.dx +
													capsSeparationVector.dy * capsSeparationVector.dy)
		return (separation > errorThreshold) ? separation : 0.0
	}
}

fileprivate extension TrailAnalyser {
	/*	Measure the how even the strokes are, i.e. the flow of the circle.
	Measure the angular distance between points, and calculate the stddev
	of them. A stddev below the treshold is snapped to zero ("good enough")
	*/
	func strokeEvenness(angleDeltas: [Double]) -> Double {
		let errorThreshold = 0.01 * (.pi / 180.0)
		
		let avg = angleDeltas.reduce(0.0, +) / Double(angleDeltas.count)
		let squaredErrors = angleDeltas.reduce(0.0) {$0 + ($1 - avg) * ($1 - avg)}
		let stddev = sqrt(squaredErrors) / Double(angleDeltas.count)
		
		if (stddev <= errorThreshold) {
			print("Snapping stroke evenness to perfect")
		}
		
		return (stddev > errorThreshold) ? stddev : 0.0
	}
	
	/*	Find area of the stroke where the points are dense or sparse.
			Given a list of angle buckets, find the number of points that
			fell into each. Find the bucket that deviates the most from the
			mean. Return its relative error and direction.
	*/
	func strokeCongestion(pointBuckets: [AngleBucket]) -> (peak: Double, angle: Double) {
		let n = pointBuckets.count
		let bucketSizes = pointBuckets.map{ $0.points.count }
		let avgBucketSize = bucketSizes.reduce(0.0) { $0 + Double($1) } / Double(n)

		// Find largest/smallest value among the averages
		var sparsestValue = -1
		var densestValue = 100000
		var sparsestIndex = -1
		var densestIndex = n + 1
		for i in 0..<n {
			let v = bucketSizes[i]
			if v > sparsestValue {sparsestValue = v; sparsestIndex = i}
			if v < densestValue {densestValue = v; densestIndex = i}
		}
	
		let sparsestDeviation = abs(Double(sparsestValue) - avgBucketSize)
		let densestDeviation = abs(Double(densestValue) - avgBucketSize)
	
		let worstBucket = (sparsestDeviation > densestDeviation) ?
			sparsestIndex : densestIndex

		return (peak: Double(bucketSizes[worstBucket]) - avgBucketSize, angle: pointBuckets[worstBucket].angle)
	}
}
