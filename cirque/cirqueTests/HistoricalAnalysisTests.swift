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
		NSFileManager.defaultManager().removeItemAtPath(TrailHistory.historyDir, error: nil)
	}
	
	func makeTrailAnalysis(points: Array<(Double, Double)>) -> TrailAnalyser {
		let t = Trail(tuples: points)
		let cf = CircleFitter()
		let fit = cf.fitCenterAndRadius(t.points)!
		let polar = Circle().polarizePoints(t.points, around: fit.center)
		return TrailAnalyser(points: polar, fitRadius: Double(fit.radius))
	}
	
	func testBuildsTrailHistory() {
		let trail1 = makeTrailAnalysis(circle1)
		let trail2 = makeTrailAnalysis(circle2)
		let trail3 = makeTrailAnalysis(circle3)
		
		let history = TrailHistory()
		history.addAnalysis(trail1)
		history.addAnalysis(trail2)
		history.addAnalysis(trail3)
		
		XCTAssertEqual(history.entries.count, 3, "Did not track all added histories")
		XCTAssertEqual(history.entries[0].points.count, trail1.points.count, "Did not pack in order")
		XCTAssertEqual(history.entries[1].points.count, trail2.points.count, "Did not pack in order")
		XCTAssertEqual(history.entries[2].points.count, trail3.points.count, "Did not pack in order")
	}

	func testPersistsTrailHistory() {
		let trail1 = makeTrailAnalysis(circle1)
		let trail2 = makeTrailAnalysis(circle2)
		
		let history1 = TrailHistory(filename: "testhistory.trails")
		history1.addAnalysis(trail1)
		history1.save()
		
		let history2 = TrailHistory(filename: "testhistory.trails")
		history2.addAnalysis(trail2)
		history2.save()
		
		let history3 = TrailHistory(filename: "testhistory.trails")
		XCTAssertEqual(history3.entries.count, 2, "Did not save all added histories")
		XCTAssertEqual(history3.entries[0].points.count, trail1.points.count, "Did not save in order")
		XCTAssertEqual(history3.entries[1].points.count, trail2.points.count, "Did not save in order")
	}

	func testCanDetectLinearImprovement() {

		let history = TrailHistory()
		for trail in linearImprovement {
			let ta = makeTrailAnalysis(trail)
			history.addAnalysis(ta)
		}
		
		let fitnessProgression = history.circularityScoreProgression()
		XCTAssertGreaterThan(fitnessProgression, 0.0, "Fitness should be improving")
	}

	func testCanDetectLinearWorsening() {
		let history = TrailHistory()
		for trail in linearImprovement.reverse() {
			let ta = makeTrailAnalysis(trail)
			history.addAnalysis(ta)
		}
		
		let fitnessProgression = history.circularityScoreProgression()
		XCTAssertLessThan(fitnessProgression, 0.0, "Fitness should be worsening")
	}

	func testCanDetectStagnantImprovement() {
		let history = TrailHistory()
		let ta1 = makeTrailAnalysis(linearImprovement[0])
		let ta2 = makeTrailAnalysis(linearImprovement[1])
		for i in 0..<5 {
			history.addAnalysis(ta1)
			history.addAnalysis(ta2)
		}
		
		let fitnessProgression = history.circularityScoreProgression()
		XCTAssertEqualWithAccuracy(fitnessProgression, 0.0, 0.05, "Fitness should be worsening")
	}
//
//	func testCanDiscernDominantErrorType() {
//		XCTFail("Not implemented: Type-value of error enum in history")
//	}
//	
//	func testCanDetectDominantErrorPosition() {
//		XCTFail("Not implemented: Significant error sum peak for history bucket > 1 sigma")
//	}
//
//	func testCanDetermineBestRadiusForPlayer() {
//		XCTFail("Not implemented: find covariation between low error and radius")
//	}
}