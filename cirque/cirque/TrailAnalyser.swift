//
//  TrailAnalyser.swift
//  cirque
//
//  Created by Ivan Milles on 30/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

class TrailAnalyser: NSObject {
	let points: PolarArray!
	var angleDeltas: Array<Double>?
	
	init(points polarPoints: PolarArray) {
		super.init()
		self.points = polarPoints
	}
	
	/*	Measure the relative RMS of radial errors, i.e. how round the circle is.
			Given a fitted circle, calculate each point's radial displacement from
			the fit. Find the RMS relative to the size of the circle. */
	func calculateFitError(radius: CGFloat) -> Float {
		let deviations = deviationsFromFit(radius)
		let rmsError = sqrt(deviations.reduce(0.0) {$0 + $1 * $1} / CGFloat(deviations.count))
		return Float(rmsError / radius)
	}
	
	/*	Measure the how even the strokes are, i.e. the flow of the circle.
			Measure the angular distance between points, and calculate the stddev
			of them. A stddev below the treshold is snapped to zero ("good enough")
	*/
	func strokeEvenness() -> Double {
		let errorThreshold = 5.0 * M_PI / 180.0
		
		if angleDeltas == nil {
			angleDeltas = angleDeltas(points)
		}
		
		let ad = angleDeltas!
		
		let avg = ad.reduce(0.0, +) / Double(ad.count)
		let stddev = sqrt(ad.reduce(0.0) {$0 + ($1 - avg) * ($1 - avg)} / Double(ad.count))
		if stddev < errorThreshold {return 0.0}
		return stddev
	}
	
	/*	Find area of the stroke where the points are dense or sparse.
			Given a list of the gaps between points, calculate a moving average
			with a window size of 45º around the circle. Report the largest absolute
			deviation from the mean. A low value means dense points; a high value
			means sparse points. Report the value and map its center to an angle.
	*/
	func strokeCongestion() -> (peak: Double, angle: CGFloat) {
		if angleDeltas == nil {
			angleDeltas = angleDeltas(points)
		}
		
		let ad = angleDeltas!
		let mean = ad.reduce(0.0, +) / Double(ad.count)
		
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
		var maxValue = -1.0
		var minValue = 100000.0
		var maxIndex = -1
		var minIndex = n + 1
		for i in 0..<n {
			let v = smoothed[i]
			if v > maxValue {maxValue = v; maxIndex = i}
			if v < minValue {minValue = v; minIndex = i}
		}
		
		// Figure out if the error is sparse or dense
		maxValue = abs(maxValue - mean)
		minValue = abs(minValue - mean)
		
		// Return the largest value and its associated angle (taken from center of window)
		var outV = 0.0
		var outI = 0
		if (maxValue > minValue) {outV = maxValue; outI = maxIndex}
		else {outV = minValue; outI = minIndex}
		outI = (outI + windowSize / 2) % n	// Take index from center of window
		
		return (peak: outV, angle: points[outI].a)
	}
	
	func deviationsFromFit(radius: CGFloat) -> Array<CGFloat> {
		return points.map {$0.r - radius}
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