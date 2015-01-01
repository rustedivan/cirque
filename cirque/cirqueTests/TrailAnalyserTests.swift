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
	
	func polariseTestPoints(points: Array<(Double, Double)>, inout toRadius radius: CGFloat) -> PolarArray {
		let t = Trail(tuples: points)
		let cf = CircleFitter()
		let fit = cf.fitCenterAndRadius(t.points)
		radius = fit.radius
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
		var discard: CGFloat = 0.0
		
		let unevenTrail = polariseTestPoints(unevenStrokeTrail, toRadius: &discard)
		let evenTrail = polariseTestPoints(evenStrokeTrail, toRadius: &discard)
		let perfectTrail = polariseTestPoints(perfectStrokeTrail, toRadius: &discard)
		
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
		var discard: CGFloat = 0.0
		let congestionDown = polariseTestPoints(congestedDown, toRadius: &discard)
		let congestionUpLeft = polariseTestPoints(congestedUpperLeft, toRadius: &discard)
		let congestionD = TrailAnalyser(points: congestionDown).strokeCongestion()
		let congestionUL = TrailAnalyser(points: congestionUpLeft).strokeCongestion()
		
		XCTAssertGreaterThan(congestionD.peak, 0.0, "Did not calculate congestion")
		XCTAssertEqualWithAccuracy(congestionD.angle, CGFloat(3.0 * M_PI_2), 0.03, "Did not direct congestion")
		XCTAssertGreaterThan(congestionUL.peak, 0.0, "Did not calculate congestion")
		XCTAssertEqualWithAccuracy(congestionUL.angle, CGFloat(3.0 * M_PI_4), 0.03, "Did not direct congestion")
	}
	
	/* Radial deviations: given a fit circle, calculate the residial vector of radial samples.
	*/
	func testCalculateRadialDeviations() {
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
	
	/* Radial deviation: given all relative radial displacements, calculate the RMS of them.
	*/
	func testFindRadialFitness() {
		var bumpyRadius: CGFloat = 0.0;
		var roundRadius: CGFloat = 0.0;
		var perfectRadius: CGFloat = 0.0
		
		let bumpyTrail = polariseTestPoints(bumpyCircleTrail, toRadius: &bumpyRadius)
		let roundTrail = polariseTestPoints(roundCircleTrail, toRadius: &roundRadius)
		let perfectTrail = polariseTestPoints(perfectCircleTrail, toRadius: &perfectRadius)
		
		let bad = TrailAnalyser(points: bumpyTrail).radialFitness(bumpyRadius)
		let good = TrailAnalyser(points: roundTrail).radialFitness(roundRadius)
		let perfect = TrailAnalyser(points: perfectTrail).radialFitness(perfectRadius)
		
		XCTAssertLessThan(good, bad, "Uneven circle should have higher error than even stroke")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect circle should snap error to zero")
		
		let largeBadTrail = bumpyTrail.map{Polar(r: $0.r * 10.0, a: $0.a)}
		let largeBad = TrailAnalyser(points: largeBadTrail).radialFitness(bumpyRadius * 10.0)
		XCTAssertEqualWithAccuracy(largeBad, bad, 0.01, "Scaling the circle shouldn't cause larger error")
	}
	
	/* Report whether the RMS of the last 1/4 of the circle is significantly tighter
		 or looser than the first 1/4.
	*/
	func testFindRadialContractionOrExpansion() {
		var discard: CGFloat = 0.0
		
		let contractingTrail = polariseTestPoints(radialContractionTrail, toRadius: &discard)
		let expandingTrail = polariseTestPoints(radialExpansionTrail, toRadius: &discard)
		let perfectTrail = polariseTestPoints(perfectContractionTrail, toRadius: &discard)
		
		let contraction = TrailAnalyser(points: contractingTrail).radialContraction()
		let expansion = TrailAnalyser(points: expandingTrail).radialContraction()
		let perfect = TrailAnalyser(points: perfectTrail).radialContraction()
		
		XCTAssertLessThan(contraction, 0.0, "Contracting circle should be negative")
		XCTAssertGreaterThan(expansion, 0.0, "Expanding circle should be positive")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect circle should snap error to zero")
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
