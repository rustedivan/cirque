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

// TODO: functional approach to analysis
// - two types of analysis
// -- ScalarAnalyser: ([PolarArray] -> Double)
// -- SeriesAnalyser: ([PolarArray] -> (peak, angle))

struct TrailAnalysis: Equatable, CustomDebugStringConvertible {
	let isCircle: Bool
	let isClockwise: Bool
	let circularityScore: Double
	let radialFitness: Double
	let radialContraction: Double
	let endCapsSeparation: Double
	let strokeEvenness: Double
	let radialDeviation: (peak: Double, angle: Double)
	let strokeCongestion: (peak: Double, angle: Double)
	let hint: HintType?
	
	static func ==(lhs: TrailAnalysis, rhs: TrailAnalysis) -> Bool {
		if lhs.isCircle != rhs.isCircle { return false }
		if lhs.isClockwise != rhs.isClockwise { return false }
		if lhs.circularityScore != rhs.circularityScore { return false }
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
		out += "\tDirection:        \(isClockwise ? "clockwise" : "counter-clockwise")"
		out += "\tCircularity:"
		out += "\t- score:          \(Int(circularityScore * 100.0))%"
		out += "\t- radial fitness: \(Int(radialFitness * 100.0))%"
		out += "\t- contraction:    \(radialContraction)"
		out += "\t- cap separation: \(Int(endCapsSeparation)) pixels"
		out += "\tRadial deviation:"
		out += "\t- peak:           \(Int(radialDeviation.peak))"
		out += "\t- angle:          \(Int((radialDeviation.angle / M_PI) * 180.0))º"
		out += "\tStroke evenness:"
		out += "\t- peak:           \(Int(strokeCongestion.peak))"
		out += "\t- angle:          \(Int((strokeCongestion.angle / M_PI) * 180.0))º"
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
		return TrailAnalysis(isCircle: false, isClockwise: false, circularityScore: 0.0, radialFitness: 0.0, radialContraction: 0.0, endCapsSeparation: 0.0, strokeEvenness: 0.0, radialDeviation: (peak: 0.0, angle: 0.0), strokeCongestion: (peak: 0.0, angle: 0.0), hint: nil)
	}
	
	class func binPointsByAngle(_ points: PolarArray, intoBuckets buckets: Int) -> [AngleBucket] {
		var histogram = [AngleBucket](repeating: ([], 0.0), count: buckets)
		let nBuckets = Double(buckets)
		
		for i in 0..<buckets {
			histogram[i].angle = (2.0 * M_PI / nBuckets) * Double(i)
		}
		
		let bucketWidth = 2.0 * M_PI / nBuckets
		for p in points {
			let i = Int(p.a / bucketWidth)
			histogram[i].points.append(p)
		}
		return histogram
	}
	
	
}

fileprivate extension TrailAnalyser {
	/*	Grade the radial deviations on a reverse quadratic curve.
			Approved radial fitnesses lie on 0.0...0.1, so scale that up
			by a factor of 10 and clamp it to normalize. Reverse and square.
	*/
	func circularityScore(radialFitness: Double) -> Double {
		let errorInterval = 0.0...1.0
		let errorScale = 10.0
		let scaledError = radialFitness * errorScale
		let lowerBound = min(scaledError, errorInterval.upperBound)
		let error = max(lowerBound, errorInterval.lowerBound)
		let score = error - (errorInterval.upperBound - errorInterval.lowerBound)
		let gradedScore = score * score
		return gradedScore
	}
	
	func calcBucketErrors(pointBuckets: [AngleBucket], fromRadius radius: Double) -> [Double] {
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
	func radialContraction(points: PolarArray) -> Double {
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
	
	func deviationsFromFit(points: PolarArray, fromRadius radius: Double) -> [Double] {
		return points.map { $0.r - radius }
	}
}

fileprivate extension TrailAnalyser {
	func endCapsSeparation(points: PolarArray) -> Double {
		let errorThreshold = 10.0
		
		let startPolar = points.first!
		let startPoint = Point(x: cos(startPolar.a) * startPolar.r, y: sin(startPolar.a) * startPolar.r)
		let endPolar = points.last!
		let endPoint = Point(x: cos(endPolar.a) * endPolar.r, y: sin(endPolar.a) * endPolar.r)
		
		let capsSeparationVector = Vector(dx: endPoint.x - startPoint.x, dy: endPoint.y - startPoint.y)
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
		let errorThreshold = 0.01 * (M_PI / 180.0)
		
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

fileprivate extension TrailAnalyser {
	func isCircle(pointBuckets: [AngleBucket], radialFitness: Double, endCapsSeparation: Double, fitRadius radius: Double) -> Bool {
		// Circle must be closed
		let endCapErrorThreshold = radius / 2.0	// Caps are off by half the radius
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
		
		// Circle must be complete
		for bucket in pointBuckets {
			if bucket.points.isEmpty {
				print("Rejected completeness: point bucket at \(bucket.angle) is empty")
				return false
			}
		}
		
		return true
	}
}
