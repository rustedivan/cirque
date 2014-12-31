//
//  CircleAnalyzer.swift
//  cirque
//
//  Created by Ivan Milles on 28/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import UIKit
import XCTest

class CircleAnalyzer: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}
	
	func polariseTestPoints(points: Array<(Double, Double)>) -> PolarArray {
		let t = Trail(tuples: points)
		let cf = CircleFitter()
		let fit = cf.fitCenterAndRadius(t.points)
		return Circle().polarizePoints(t.points, around: fit.center)
	}
	
	/* All in all: the error measure that contributed the most to the error (weighted somehow?)
								 is displayed with a helpful message. Harsher wording at high percentiles, but
								 trigger try-again instinct.
								 All error factors are weighted (stroke evenness is light, cap separation is heavy.
								 All measurements are taken wrt the ideal circle.
	*/
	
	
	/*
		Circularity score: 100% for 99-perfect circle with 99-perfect spacing, snap 99 to 100 (should be possible!)
											 inbetween, exponential response curve (lots of scoring resolution at the top)
											 0% for any circle that doesn't meet all bottom requirements (not even a circle)
	*/
	
	
	func testCalculateCircularity() {
	}

	/* Evenness:	given all angular points, calculate dA for all of them
								given this list of angular displacements, calc SD of them
								evenness is also rated on an exponential scale, 99-snapped
	*/
	func testCalculateStrokeEvenness() {
		let unevenTrail = polariseTestPoints(unevenStrokeTrail)
		let evenTrail = polariseTestPoints(evenStrokeTrail)
		let perfectTrail = polariseTestPoints(perfectStrokeTrail)
		
		let bad = TrailAnalyser(points: unevenTrail).strokeEvenness()
		let good = TrailAnalyser(points: evenTrail).strokeEvenness()
		let perfect = TrailAnalyser(points: perfectTrail).strokeEvenness()
		
		XCTAssertLessThan(good, bad, "Uneven stroke should have higher error than even stroke")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect stroke should snap error to zero")
	}
	
	/* Congestion direction:	given all angular displacements, calc exponential sliding average
														to filter the data down to 8 cardinal points. Find max-deviation.
	*/
	func testFindStrokeCongestionDirection() {
		let congestionDown = polariseTestPoints(congestedDown)
		let congestion = TrailAnalyser(points: congestionDown).strokeCongestion()
		
		XCTAssertGreaterThan(congestion.peak, 0.0, "Did not calculate congestion")
		XCTAssertEqualWithAccuracy(congestion.angle, CGFloat(3.0 * M_PI_2), 0.03, "Did not direct congestion")
	}
	
	/* Radial evenness: calculate RMS of all radial offsets from ideal radius
											relative to the size of the circle.
	*/
	func testCalculateRadialEvenness() {
		var points: PolarArray = [	(a: 0.0, r: 100.0),
																(a: 90.0, r: 95.0),
																(a: 180.0, r: 105.0),
																(a: 270.0, r: 150.0)]

		let deviations = TrailAnalyser(points: points).deviationsFromFit(CGFloat(100.0))
		XCTAssertEqualWithAccuracy(deviations[0], CGFloat(0.0), 0.0, "Deviation incorrect")
		XCTAssertEqualWithAccuracy(deviations[1], CGFloat(-5.0), 0.0, "Deviation incorrect")
		XCTAssertEqualWithAccuracy(deviations[2], CGFloat(5.0), 0.0, "Deviation incorrect")
		XCTAssertEqualWithAccuracy(deviations[3], CGFloat(50.0), 0.0, "Deviation incorrect")
	}
	
	/* Radial deviations: given all relative radial displacements, find the max and min values.
	*/
	
	func testFindRadialDeviationsPeakPositive() {
	}
	
	func testFindRadialDeviationsPeakNegative() {
	}
	
	/* Report whether the RMS of the last 1/4 of the circle is significantly tighter
		 or looser than the first 1/4.
	*/
	func testFindRadialContractionOrExpansion() {
	}
	
	/* Measure the distance in pixels between the start and end caps in absolute distance.
		 (Making the caps line up isn't significantly harder for large circles.)
		 Snap to zero if the distance is less than the width of the stroke.
	*/

	func testFindStartEndCapsSeparation() {
	}
	
	/* Calculate a linear fit for the slope of the last 10% of the circle's radial measuremets.
		 Any slope that significantly deviates form zero is reported as positive or negative.
	*/
	func testFindAngleOfAttackOfStrokeEnd() {
	}
	
	func testShouldRejectNonClosedCircle() {
	}

	func testShouldRejectNotEvenCloseToCircle() {
	}
}
