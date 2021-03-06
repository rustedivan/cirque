//
//  HistoricalAnalysisTests.swift
//  cirque
//
//  Created by Ivan Milles on 14/01/15.
//  Copyright (c) 2015 Rusted. All rights reserved.
//

import XCTest

/* 
	Historical analysis:
	Given a series of circles, find the angle that gives the
	largest "error" volume. This is where the player consistently
	makes mistakes.

	"Error volume" is calculated as follows:
	For each circle:
	√ bucket all angles into N buckets
	√ calculate the sum-of-squares error in each bucket
	For each new circle:
	- store the entire trail in history
	- compress trail history somehow
	For each bucket:
	- calculate a Gaussian average over M-width bucket window
	- calculate an exponential cumulative error on each bucket bell
	- the bucket with the highest cumulative error is the current error
	For each history insertion:
	- install time test on historical error calculation
	- fast average insertion: (total error metric + new error metric) / (N + 1)

	Questions to answer:
	- "is the player getting better?"
	- what is the dominant error type in recent history?
	- what is the peak trend on that error type?
	- where does that error type happen?
	- what is the location trend on that error type?
	- is there a correlation between fitness and radius? What is the best radius for the player?

	Next:
	- store a time series on the most offending bucket
	- see if we can do something cool with it
	- only give historical reports every 20th circle or so
	- only give historical reports after significant improvement
	- long-term persistence of circle samples to show improvement over time
*/

class HistoricalAnalysisTests: XCTestCase {
	
	override func tearDown() {
		do {
			try FileManager.default.removeItem(atPath: TrailHistory.historyDir)
		} catch _ {
		}
	}
	
	func testAnalysis(seed: Int) -> TrailAnalysis {
		let seedVal = Double(seed)
		return TrailAnalysis(circleFit: CircleFit(center: Point(10.0 * seedVal, -2.0 * seedVal),
		                                          radius: 15.0 * seedVal),
		                     isClockwise: (seed % 3 > 0),
		                     isComplete: true,
		                     radialFitness: 0.05 - 0.01 * seedVal, // Lower is better
		                     radialContraction: -0.1 * seedVal,
		                     endCapsSeparation: seedVal,
		                     strokeEvenness: seedVal + 0.5,
		                     radialDeviation: (peak: 0.15 * seedVal, angle: (.pi/2.0) + seedVal * 0.01),
		                     strokeCongestion: (peak: 0.25 * seedVal, angle: -seedVal))
	}
	
	func testLinearTrend() {
		let values = [52.21, 53.12, 54.48, 55.84, 57.20, 58.57, 59.93, 61.29, 63.11, 64.47]
		let trend = linearTrend(values)
		XCTAssertEqualWithAccuracy(trend, 1.38, accuracy: 0.01)
	}
	
	func testShouldStoreOneAnalysis() {
		let a = testAnalysis(seed: 1)
		
		let h = TrailHistory(filename: "testhistory.analysis")
		h.addAnalysis(a)
		
		XCTAssertEqualWithAccuracy(h.history.scoreHistory.average, a.circularityScore, accuracy: 0.01)
		
	}
	
	func testShouldCalculateTrendAnalysis() {
		let a1 = testAnalysis(seed: 1)
		let a2 = testAnalysis(seed: 2)
		let a3 = testAnalysis(seed: 3)
		let a4 = testAnalysis(seed: 4)
		let a5 = testAnalysis(seed: 5)
		
		let h = TrailHistory(filename: "testhistory.analysis")
		h.addAnalysis(a1)
		h.addAnalysis(a2)
		h.addAnalysis(a3)
		h.addAnalysis(a4)
		h.addAnalysis(a5)
		
		// Trend tests
		let a = h.trendAnalysis
		// Score is increasing
		XCTAssertGreaterThanOrEqual(a.score, 0.1)
		// Radius is increasing
		XCTAssertEqualWithAccuracy(a.radius, 15.0, accuracy: 0.01)
		// Most often clockwise
		XCTAssertEqual(a.clockwise, true)
		// Fitness is improving
		XCTAssertEqualWithAccuracy(a.fitness, -0.01, accuracy: 0.01)
		// Contraction distance is getting worse
		XCTAssertEqualWithAccuracy(a.contraction, 0.1, accuracy: 0.01)
		// End cap distance is getting worse
		XCTAssertEqualWithAccuracy(a.capSeparation, 1.0, accuracy: 0.01)
		// Outward bump to the north
		XCTAssertGreaterThan(a.radialDeviation.direction, 0.0)
		XCTAssertEqualWithAccuracy(a.radialDeviation.angle, .pi/2.0, accuracy: 0.1)
	}
	
	func testShouldPersistAnalysis() {
		let a0 = testAnalysis(seed: 1)
		let a1 = testAnalysis(seed: 2)

		do {
			let h = TrailHistory(filename: "testhistory.analysis")
			h.addAnalysis(a0)
			h.addAnalysis(a1)
			h.save()
		}
		
		do {
			let h = TrailHistory(filename: "testhistory.analysis")
			let s0 = Double(h.history.scoreHistory.timeSeries[0])
			let s1 = Double(h.history.scoreHistory.timeSeries[1])
			let f0 = Double(h.history.fitnessHistory.timeSeries[0])
			let f1 = Double(h.history.fitnessHistory.timeSeries[1])
			
			XCTAssertEqualWithAccuracy(s0, a0.circularityScore, accuracy: 0.001)
			XCTAssertEqualWithAccuracy(s1, a1.circularityScore, accuracy: 0.001)
			XCTAssertEqualWithAccuracy(f0, a0.radialFitness, accuracy: 0.001)
			XCTAssertEqualWithAccuracy(f1, a1.radialFitness, accuracy: 0.001)
			
			XCTAssertEqual(h.history.radiusHistory.timeSeries.count, 2)
			XCTAssertEqual(h.history.clockwiseHistory.timeSeries.count, 2)
			XCTAssertEqual(h.history.contractionHistory.timeSeries.count, 2)
			XCTAssertEqual(h.history.capSeparationHistory.timeSeries.count, 2)
			XCTAssertEqual(h.history.deviationAngleHistory.timeSeries.count, 2)
			XCTAssertEqual(h.history.deviationMagnitudeHistory.timeSeries.count, 2)
		}
	}
}


























