//
//  TrailAnalyser.swift
//  cirque
//
//  Created by Ivan Milles on 30/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

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

class TrailAnalyser: NSObject {
	let points: PolarArray!
	let pointBuckets: [AngleBucket]!
	let radius: Double
	let analysisBuckets = 36
	var angleDeltas: Array<Double>?
	
	
	init(points polarPoints: PolarArray, fitRadius radius: Double) {
		self.points = polarPoints
		self.radius = radius

		super.init()

		self.pointBuckets = binPointsByAngle(buckets: analysisBuckets)
	}
	
	func binPointsByAngle(#buckets: Int) -> [AngleBucket] {
		var histogram = [AngleBucket](count: buckets, repeatedValue: ([], 0.0))
		let nBuckets = CGFloat(buckets)
		
		for i in 0..<buckets {
			histogram[i].angle = (CGFloat(2.0 * M_PI) / nBuckets) * CGFloat(i)
		}
		
		let bucketWidth = CGFloat(2.0 * M_PI) / nBuckets
		for p in points {
			let i = Int(p.a / bucketWidth)
			histogram[i].points.append(p)
		}
		return histogram
	}
}

extension TrailAnalyser {
	/*	Grade the radial deviations on a reverse quadratic curve.
			Approved radial fitnesses lie on 0.0...0.1, so scale that up
			by a factor of 10 and clamp it to normalize. Reverse and square.
	*/
	func circularityScore() -> Double {
		let errorInterval = 0.0...1.0
		let errorScale = 10.0
		let error = max(min(radialFitness() * errorScale, errorInterval.end), errorInterval.start)
		let score = error - (errorInterval.end - errorInterval.start)
		let gradedScore = score * score
		return gradedScore
	}
	
	/*	Measure the relative RMS of radial errors, i.e. how round the circle is.
			Given a fitted circle, calculate each point's radial displacement from
			the fit. Find the RMS relative to the size of the circle. */
	func radialFitness() -> Double {
		let errorThreshold = 0.02

		let deviations = deviationsFromFit()
		let rmsError = sqrt(deviations.reduce(0.0) {$0 + $1 * $1} / Double(deviations.count))
		let relativeRMS = rmsError / radius
		
		return (relativeRMS > errorThreshold) ? relativeRMS : 0.0
	}
	
	/*	Find area of the stroke where radius diverges from its ideal path.
			Calculate a moving average on the radius samples with a window size of 45º
			around the circle. Report the largest absolute deviation from the mean.
			Report the value and map its center to an angle.
	*/
	func radialDeviation() -> (peak: Double, angle: CGFloat) {
		let errorThreshold = 1.0
		
		// Calculate moving average
		let n = analysisBuckets
		var bucketErrors = Array<Double>(count: n, repeatedValue: 0.0)
		for i in 0..<n {
			let bucket = pointBuckets[i]
			var bucketError = 0.0
			for p in bucket.points {
				let e = Double(p.r) - radius
				bucketError += e * e
			}
			bucketErrors[i] = bucketError
		}
		
		// Find largest/smallest value among the buckets
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
			let e = Double(r) - radius
			if abs(e) > abs(peakError) {
				peakError = e
			}
		}
		
		return (abs(peakError) > errorThreshold) ? (peak: peakError, angle: pointBuckets[largestIndex].angle) :
																											 (peak: 0.0, angle: 0.0)
	}
	
	/*	Measure difference between radial RMS and beginnig and end of the circle.
	A contracting circle will have negative local relative radial RMS; an
	an expanding circle will have a positive LRR-RMS. */
	func radialContraction() -> Double {
		let errorThreshold = 2.0
		
		let n = points.count
		let windowSize = n / 20
		let calcRMS = { (points: Slice<Polar>) -> Double in
			sqrt(points.reduce(0.0) {$0 + Double($1.r * $1.r)} / Double(n))
		}
		
		let startPoints = points[0 ..< windowSize]
		let endPoints = points[n - windowSize ..< n]
		let startRadius = calcRMS(startPoints)
		let endRadius = calcRMS(endPoints)
		
		let contraction = endRadius - startRadius
		
		return (abs(contraction) > errorThreshold) ? contraction : 0.0
	}
	
	func deviationsFromFit() -> Array<Double> {
		return points.map {Double($0.r) - self.radius}
	}
}

extension TrailAnalyser {
	func endCapsSeparation() -> Double {
		let errorThreshold = 10.0
		
		let startPolar = points.first!
		let startPoint = CGPoint(x: cos(startPolar.a) * startPolar.r, y: sin(startPolar.a) * startPolar.r)
		let endPolar = points.last!
		let endPoint = CGPoint(x: cos(endPolar.a) * endPolar.r, y: sin(endPolar.a) * endPolar.r)
		
		let capsSeparationVector = CGVector(dx: endPoint.x - startPoint.x, dy: endPoint.y - startPoint.y)
		let separation = Double(sqrt(capsSeparationVector.dx * capsSeparationVector.dx + capsSeparationVector.dy * capsSeparationVector.dy))
		return (separation > errorThreshold) ? separation : 0.0
	}

	func endAngleOfAttack() -> Double {
		let errorTreshold = 1.0

		let n = points.count
		let windowSize = n / 20
		let endPoints = points[n - windowSize ..< n]

		let sumX = Double(endPoints.reduce(0.0) {$0 + $1.a})
		let sumY = Double(endPoints.reduce(0.0) {$0 + $1.r})
		let sumXY = Double(endPoints.reduce(0.0) {$0 + $1.a * $1.r})
		let sumXX = Double(endPoints.reduce(0.0) {$0 + $1.a * $1.a})
		
		let numerator = Double(windowSize) * sumXY - sumX*sumY
		let denominator = Double(windowSize) * sumXX - sumX*sumX
		let slope = numerator / denominator
		
		return (abs(slope) > errorTreshold) ? slope : 0.0
	}
}

extension TrailAnalyser {
	/*	Measure the how even the strokes are, i.e. the flow of the circle.
	Measure the angular distance between points, and calculate the stddev
	of them. A stddev below the treshold is snapped to zero ("good enough")
	*/
	func strokeEvenness() -> Double {
		let errorThreshold = 5.0 * M_PI / 180.0
		
		// FIXME: computed property pls
		if angleDeltas == nil {
			angleDeltas = angleDeltas(points)
		}
		
		let ad = angleDeltas!
		
		let avg = ad.reduce(0.0, +) / Double(ad.count)
		let stddev = sqrt(ad.reduce(0.0) {$0 + ($1 - avg) * ($1 - avg)} / Double(ad.count))
		return (stddev > errorThreshold) ? stddev : 0.0
	}
	
	/*	$ FIXME: Stroke evenness bias
	This method is problematic: a dense stretch means that many samples
	skew the mean toward the dense. Sparse stretches do not skew toward sparse.
	This means that it is difficult to figure out whether sparse or dense stretches
	are more deviant. The mean should be based on actual arc length, not number of samples.
	
	Find area of the stroke where the points are dense or sparse.
	Given a list of the gaps between points, calculate a moving average
	with a window size of 45º around the circle. Report the largest absolute
	deviation from the mean. A low value means dense points; a high value
	means sparse points. Report the value and map its center to an angle.
	*/
	func strokeCongestion() -> (peak: Double, angle: CGFloat) {
//		println("# Stroke congestion")
		if angleDeltas == nil {
			angleDeltas = angleDeltas(points)
		}
		
		let ad = angleDeltas!
		
		// Calculate moving average
		let n = ad.count
		let windowSize = points.count / 8
		let mask = Array<Int>(0..<windowSize)
		var smoothed = Array<Double>(count: n, repeatedValue: 0.0)
		for i in 0..<n {
			var avg = 0.0
			for j in mask {
				avg += ad[(i + j) % n]
			}
			smoothed[i] = avg / Double(windowSize)
		}
		
		// Find largest/smallest value among the averages
		var sparsestValue = -1.0
		var densestValue = 100000.0
		var sparsestIndex = -1
		var densestIndex = n + 1
		for i in 0..<n {
			let v = smoothed[i]
			if v > sparsestValue {sparsestValue = v; sparsestIndex = i}
			if v < densestValue {densestValue = v; densestIndex = i}
		}
		
		let median = (sparsestValue + densestValue) / 2.0
//		println("\tOver median: \(median)")
		
		// Figure out if the error is sparse or dense
		sparsestValue = abs(sparsestValue - median)
		densestValue = abs(densestValue - median)
//		println("\tSparsest congestion: \(sparsestValue) @ \(sparsestIndex)")
//		println("\tDensest congestion:  \(densestValue) @ \(densestIndex)")
		
		// Return the largest value and its associated angle (taken from center of window)
		var outV = 0.0
		var outI = 0
		if (sparsestValue > densestValue) {outV = sparsestValue; outI = sparsestIndex}
		else {outV = densestValue; outI = densestIndex}
		outI = (outI + windowSize / 2) % n	// Take index from center of window
		
//		println("\tMost deviant congestion: \(outV) @ \(outI)")
		let a = Double(points[outI].a) * 180.0 / M_PI
//		println("\tFound at angle: \(a)")
		return (peak: outV, angle: points[outI].a)
	}
	
	func angleDeltas(points: PolarArray) -> Array<Double> {
		var deltaA = Array<Double>()
		for i in 0 ..< points.count - 1 {
			let prev = Double(points[i].a)
			let next = Double(points[i + 1].a)
			var d = next - prev
			if d > M_PI {d -= 2.0 * M_PI}
			if d < -M_PI {d += 2.0 * M_PI}
			deltaA.append(d)
		}
		return deltaA
	}
}

extension TrailAnalyser {
	func isCircle() -> Bool {
		// Circle must be closed
		let endCapErrorThreshold = radius / 2.0	// Caps are off by half the radius
		if (self.endCapsSeparation() > endCapErrorThreshold) {
			println("Rejected end caps: \(self.endCapsSeparation()) > \(endCapErrorThreshold)")
			return false
		}

		// Circle must be round
		let radialErrorThreshold = sqrt(0.01 * (radius * radius * M_PI))	// Error area is larger than 0.5% (p^2 > E  ==> p > √E)
		let p = abs(self.radialDeviation().peak)
		if (p > radialErrorThreshold) {
			println("Rejected roundness: \(p) > \(radialErrorThreshold)")
			return false
		}
		
		// Circle must be complete
		let circleLengthThreshold = 0.95 * 2.0 * M_PI
		if angleDeltas == nil {
			angleDeltas = angleDeltas(points)
		}
		let arcLength = angleDeltas!.reduce(0.0, +)
		if (arcLength < circleLengthThreshold) {
			println("Rejected arc length: \(arcLength) < \(circleLengthThreshold)")
			return false
		}
		
		return true
	}
}


