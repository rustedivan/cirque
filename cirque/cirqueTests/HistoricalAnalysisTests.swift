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
		                     isClockwise: (seed % 2 == 0),
		                     isComplete: true,
		                     radialFitness: 0.05 - 0.01 * seedVal, // Lower is better
		                     radialContraction: -0.1 * seedVal,
		                     endCapsSeparation: seedVal,
		                     strokeEvenness: seedVal + 0.5,
		                     radialDeviation: (peak: 0.15 * seedVal, angle: seedVal),
		                     strokeCongestion: (peak: 0.25 * seedVal, angle: -seedVal))
	}
	
	func testLinearTrend() {
		let values = [52.21, 53.12, 54.48, 55.84, 57.20, 58.57, 59.93, 61.29, 63.11, 64.47]
		let trend = linearTrend(values)
		XCTAssertEqualWithAccuracy(trend, 1.38, accuracy: 0.01)
	}
	
	func testShouldStoreOneAnalysis() {
		let a = testAnalysis(seed: 1)
		
		let h = TrailHistory(filename: "testhistory.analysis", slots: (immediate: 3, trend: 2, characteristic: 1))
		h.addAnalysis(a)
		
		XCTAssertEqual(h.entries.first!, a)
	}
	
	func testShouldCalculateTrendAnalysis() {
		let a1 = testAnalysis(seed: 1)
		let a2 = testAnalysis(seed: 2)
		let a3 = testAnalysis(seed: 3)
		let a4 = testAnalysis(seed: 4)
		let a5 = testAnalysis(seed: 5)
		
		let h = TrailHistory(filename: "testhistory.analysis", slots: (immediate: 3, trend: 2, characteristic: 1))
		h.addAnalysis(a1)
		h.addAnalysis(a2)
		h.addAnalysis(a3)
		h.addAnalysis(a4)
		h.addAnalysis(a5)
		
		// Trend tests
		
		// Score is increasing
		XCTAssertGreaterThanOrEqual(h.trendAnalysis.score, 0.1)
		// Radius is increasing
		XCTAssertEqual(h.trendAnalysis.radius, 0.1)
		// Most often clockwise
		XCTAssertEqual(h.trendAnalysis.clockwise, true)
		// Fitness is improving
		XCTAssertEqual(h.trendAnalysis.fitness, 0.1)
		// Contraction distance is getting worse
		XCTAssertEqual(h.trendAnalysis.contraction, 0.1)
		// End cap distance is getting worse
		XCTAssertEqual(h.trendAnalysis.capSeparation, 0.2)
	}
	
	func testShouldDominateByNewerData() {
		let a1 = testAnalysis(seed: 3)
		let a2 = testAnalysis(seed: 3)
		let a3 = testAnalysis(seed: 3)
		
		let a4 = testAnalysis(seed: 1)
		let a5 = testAnalysis(seed: 1)
		let a6 = testAnalysis(seed: 1)
		let a7 = testAnalysis(seed: 1)
		let a8 = testAnalysis(seed: 1)
		let a9 = testAnalysis(seed: 1)
		
		let h = TrailHistory(filename: "testhistory.analysis", slots: (immediate: 3, trend: 2, characteristic: 1))
		h.addAnalysis(a1)
		h.addAnalysis(a2)
		h.addAnalysis(a3)
		XCTAssertEqual(h.trendAnalysis.fitness, 3.0)
		
		h.addAnalysis(a4)
		h.addAnalysis(a5)
		h.addAnalysis(a6)
		h.addAnalysis(a7)
		h.addAnalysis(a8)
		h.addAnalysis(a9)
		
		let straightAverage = (3 * 3.0 + 6 * 1.0) / 9.0
		XCTAssertLessThan(h.trendAnalysis.fitness, straightAverage)
	}
	
	
	func testShouldPersistAnalysis() {
	}
	
	
}


























