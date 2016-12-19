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
	
	func polariseTestPoints(points: Array<(Double, Double)>) -> (polarPoints: PolarArray, radius: Double) {
		let t = Trail(points: points)
		let fit = CircleFitter.fitCenterAndRadius(t.points)
		let p = polarize(t.points, around: fit.center)
		let r = fit.radius
		return (polarPoints: p, radius: r)
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
		let (realGoodTrail, realGoodRadius) = polariseTestPoints(points: realGoodCircleTrail)
		let (justGoodTrail, justGoodRadius) = polariseTestPoints(points: justGoodCircleTrail)
		let (justBadTrail, justBadRadius) = polariseTestPoints(points: justBadCircleTrail)
		let (realBadTrail, realBadRadius) = polariseTestPoints(points: realBadCircleTrail)

		let realGood = TrailAnalyser(points: realGoodTrail, fitRadius: realGoodRadius).circularityScore()
		let justGood = TrailAnalyser(points: justGoodTrail, fitRadius: justGoodRadius).circularityScore()
		let justBad = TrailAnalyser(points: justBadTrail, fitRadius: justBadRadius).circularityScore()
		let realBad = TrailAnalyser(points: realBadTrail, fitRadius: realBadRadius).circularityScore()

		// Assert score ordering
		XCTAssertLessThan(justGood, realGood, "Wrong order")
		XCTAssertLessThan(justBad, justGood, "Wrong order")
		XCTAssertLessThan(realBad, justBad, "Wrong order")

		// Assert more resolution for good circles
		let goodDiff = realGood - justGood
		let badDiff = justBad - realBad
		XCTAssertLessThan(badDiff, goodDiff, "Resolution curve is not shit-hot")
	}

	/* Evenness:	given all angular points, calculate dA for all of them
								given this list of angular displacements, calc SD of them
								evenness is also rated on an exponential scale, 99-snapped
	*/
	func testCalculateStrokeEvenness() {
		let (unevenTrail, _) = polariseTestPoints(points: unevenStrokeTrail)
		let (evenTrail, _) = polariseTestPoints(points: evenStrokeTrail)
		let (perfectTrail, _) = polariseTestPoints(points: perfectStrokeTrail)
		
		let bad = TrailAnalyser(points: unevenTrail, fitRadius: 0.0).strokeEvenness()
		let good = TrailAnalyser(points: evenTrail, fitRadius: 0.0).strokeEvenness()
		let perfect = TrailAnalyser(points: perfectTrail, fitRadius: 0.0).strokeEvenness()
		
		XCTAssertGreaterThan(bad, 0.0, "This stroke should not be perfect")
		XCTAssertGreaterThan(good, 0.0, "This stroke should not be perfect")
		XCTAssertLessThan(good, bad, "Uneven stroke should have higher error than even stroke")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect stroke should snap error to zero")
	}
	
	/* Congestion direction:	given all angular displacements, calc exponential sliding average
														to filter the data down to 8 cardinal points. Find max-deviation.
	*/
	func testFindStrokeCongestionDirection() {
		let (congestionDown, _) = polariseTestPoints(points: congestedDown)
		let (congestionUpLeft, _) = polariseTestPoints(points: congestedUpperLeft)
		let congestionD = TrailAnalyser(points: congestionDown, fitRadius: 10.0).strokeCongestion()
		let congestionUL = TrailAnalyser(points: congestionUpLeft, fitRadius: 10.0).strokeCongestion()
		
		XCTAssertGreaterThan(congestionD.peak, 0.0, "Did not calculate congestion")
		XCTAssertEqualWithAccuracy(congestionD.angle, 3.0 * M_PI_2, accuracy: M_PI_4, "Did not direct congestion")
		XCTAssertGreaterThan(congestionUL.peak, 0.0, "Did not calculate congestion")
		XCTAssertEqualWithAccuracy(congestionUL.angle, 3.0 * M_PI_4, accuracy: M_PI_4, "Did not direct congestion")
	}
	
	/* Radial deviations: given a fit circle, calculate the residial vector of radial samples.
	*/
//	func testCalculateRadialDeviations() {
//		let points: PolarArray = [	(a: 0.0, r: 100.0),
//																(a: M_PI_2, r: 95.0),
//																(a: M_PI, r: 105.0),
//																(a: 3.0 * M_PI_2, r: 150.0)]
//
//		let analysis = TrailAnalyser(points: points, fitRadius: 100.0)
//		let deviations = analysis.deviationsFromFit()
//		XCTAssertEqualWithAccuracy(deviations[0], 0.0, accuracy: 0.0, "Deviation incorrect")
//		XCTAssertEqualWithAccuracy(deviations[1], -5.0, accuracy: 0.0, "Deviation incorrect")
//		XCTAssertEqualWithAccuracy(deviations[2], 5.0, accuracy: 0.0, "Deviation incorrect")
//		XCTAssertEqualWithAccuracy(deviations[3], 50.0, accuracy: 0.0, "Deviation incorrect")
//	}
	
	/* Radial deviations: given all relative radial displacements, find the largest deviation from circle
	*/
	func testFindRadialDeviationsPeak() {
		let (bumpOutULTrail, bumpOutRadius) = polariseTestPoints(points: upperLeftBumpOut)
		let (bumpInDTrail, bumpInRadius) = polariseTestPoints(points: downBumpIn)
		let (flatRightTrail, flatRightRadius) = polariseTestPoints(points: flatBumpRight)
		let (noBumpTrail, noBumpRadius) = polariseTestPoints(points: almostNoBump)
		
		let bumpOutUL = TrailAnalyser(points: bumpOutULTrail, fitRadius: bumpOutRadius).radialDeviation()
		let bumpInD = TrailAnalyser(points: bumpInDTrail, fitRadius: bumpInRadius).radialDeviation()
		let flatRight = TrailAnalyser(points: flatRightTrail, fitRadius: flatRightRadius).radialDeviation()
		let noBump = TrailAnalyser(points: noBumpTrail, fitRadius: noBumpRadius).radialDeviation()
		
		XCTAssertGreaterThan(bumpOutUL.peak, 0.0, "Did not calculate deviation")
		XCTAssertEqualWithAccuracy(bumpOutUL.angle, 3.0 * M_PI_4, accuracy: 0.30, "Did not find deviation")

		XCTAssertLessThan(bumpInD.peak, 0.0, "Did not calculate deviation")
		XCTAssertEqualWithAccuracy(bumpInD.angle, 6.0 * M_PI_4, accuracy: 0.30, "Did not find deviation")

		XCTAssertLessThan(flatRight.peak, 0.0, "Did not calculate deviation")
		XCTAssertEqualWithAccuracy(flatRight.angle, 0.0, accuracy: 0.30, "Did not find deviation")

		XCTAssertEqual(noBump.peak, 0.0, "Did not calculate deviation")
	}

	/* Radial deviation: given all relative radial displacements, calculate the RMS of them.
	*/
	func testFindRadialFitness() {
		let (bumpyTrail, bumpyRadius) = polariseTestPoints(points: bumpyCircleTrail)
		let (roundTrail, roundRadius) = polariseTestPoints(points: roundCircleTrail)
		let (perfectTrail, perfectRadius) = polariseTestPoints(points: perfectCircleTrail)
		
		let bad = TrailAnalyser(points: bumpyTrail, fitRadius: bumpyRadius).radialFitness()
		let good = TrailAnalyser(points: roundTrail, fitRadius: roundRadius).radialFitness()
		let perfect = TrailAnalyser(points: perfectTrail, fitRadius: perfectRadius).radialFitness()
		
		XCTAssertLessThan(good, bad, "Uneven circle should have higher error than even stroke")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect circle should snap error to zero")
		
		let largeBadTrailScaled = bumpyCircleTrail.map{TestPoint($0.0 * 100.0, $0.1 * 100.0)}
		let (largeBadTrail, largeBadRadius) = polariseTestPoints(points: largeBadTrailScaled)
		let largeBad = TrailAnalyser(points: largeBadTrail, fitRadius: largeBadRadius).radialFitness()
		XCTAssertEqualWithAccuracy(largeBad, bad, accuracy: 0.01, "Scaling the circle shouldn't cause larger error")
	}
	
	/* Report whether the RMS of the last 1/4 of the circle is significantly tighter
		 or looser than the first 1/4.
	*/
	func testFindRadialContractionOrExpansion() {
		let (contractingTrail, _) = polariseTestPoints(points: radialContractionTrail)
		let (expandingTrail, _) = polariseTestPoints(points: radialExpansionTrail)
		let (perfectTrail, _) = polariseTestPoints(points: perfectContractionTrail)
		
		let contraction = TrailAnalyser(points: contractingTrail, fitRadius: 10.0).radialContraction()
		let expansion = TrailAnalyser(points: expandingTrail, fitRadius: 10.0).radialContraction()
		let perfect = TrailAnalyser(points: perfectTrail, fitRadius: 10.0).radialContraction()
		
		XCTAssertLessThan(contraction, 0.0, "Contracting circle should be negative")
		XCTAssertGreaterThan(expansion, 0.0, "Expanding circle should be positive")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect circle should snap error to zero")
	}
	
	/* Measure the distance in pixels between the start and end caps in absolute distance.
		 (Making the caps line up isn't significantly harder for large circles.)
		 Snap to zero if the distance is less than the width of the stroke.
	*/

	func testFindStartEndCapsSeparation() {
		let (distantCapsTrail, _) = polariseTestPoints(points: distantCaps)
		let (veryDistantCapsTrail, _) = polariseTestPoints(points: veryDistantCaps)
		let (perfectTrail, _) = polariseTestPoints(points: perfectCaps)
		
		let distant = TrailAnalyser(points: distantCapsTrail, fitRadius: 10.0).endCapsSeparation()
		let veryDistant = TrailAnalyser(points: veryDistantCapsTrail, fitRadius: 10.0).endCapsSeparation()
		let perfect = TrailAnalyser(points: perfectTrail, fitRadius: 10.0).endCapsSeparation()
		
		XCTAssertGreaterThan(veryDistant, distant, "More distant caps should be a larger error")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect end caps should snap error to zero")
	}
	
	func testShouldRejectNonClosedCircle() {
		let (notClosedTrail, radius) = polariseTestPoints(points: notClosed)
		let reject = TrailAnalyser(points: notClosedTrail, fitRadius: radius).isCircle()
		
		XCTAssertFalse(reject, "Nonclosed circle should be rejected")
	}

	func testShouldRejectNotEvenCloseToCircle() {
		let (squareTrail, radius1) = polariseTestPoints(points: square)
		let (eightTrail, radius2) = polariseTestPoints(points: eight)
		let reject1 = TrailAnalyser(points: squareTrail, fitRadius: radius1).isCircle()
		let reject2 = TrailAnalyser(points: eightTrail, fitRadius: radius2).isCircle()
		
		XCTAssertFalse(reject1, "Nonround circle should be rejected")
		XCTAssertFalse(reject2, "Nonround circle should be rejected")
	}
	
	func testShouldRejectSegments() {
		let (lineSegmentTrail, radius1) = polariseTestPoints(points: lineSegment)
		let (arcSegmentTrail, radius2) = polariseTestPoints(points: arcSegment)
		let reject1 = TrailAnalyser(points: lineSegmentTrail, fitRadius: radius1).isCircle()
		let reject2 = TrailAnalyser(points: arcSegmentTrail, fitRadius: radius2).isCircle()
		
		XCTAssertFalse(reject1, "Noncomplete circle should be rejected")
		XCTAssertFalse(reject2, "Noncomplete circle should be rejected")
	}
	
	func testShouldAcceptHonestCircle() {
		let (circleTrail, radius) = polariseTestPoints(points: properCircle)
		let accept = TrailAnalyser(points: circleTrail, fitRadius: radius).isCircle()
		
		XCTAssertTrue(accept, "Complete circle should be accepted")
	}
	
	func testCircleShouldBinAngles() {
		let buckets = TrailAnalyser.binPointsByAngle(binTestCircle, intoBuckets: 4)
		
		XCTAssertEqual(buckets.count, 4, "Wrong number of buckets")
		
		XCTAssertEqual(buckets[0].points.count, 18, "Wrong number of points in bucket 0")
		XCTAssertEqual(buckets[1].points.count, 10, "Wrong number of points in bucket 1")
		XCTAssertEqual(buckets[2].points.count, 8, "Wrong number of points in bucket 2")
		XCTAssertEqual(buckets[3].points.count, 9, "Wrong number of points in bucket 3")
		
		XCTAssertEqualWithAccuracy(buckets[0].angle, 0.0, accuracy: 0.01, "Bucket 0 in wrong direction")
		XCTAssertEqualWithAccuracy(buckets[1].angle, M_PI_2, accuracy: 0.01, "Bucket 1 in wrong direction")
		XCTAssertEqualWithAccuracy(buckets[2].angle, M_PI, accuracy: 0.01, "Bucket 2 in wrong direction")
		XCTAssertEqualWithAccuracy(buckets[3].angle, 3.0 * M_PI_2, accuracy: 0.01, "Bucket 3 in wrong direction")
	}
	
	func testTrailAnalysisPerformance() {
		let (testTrail, radius) = polariseTestPoints(points: eight)
		self.measure() {
			let _ = TrailAnalyser(points: testTrail, fitRadius: radius)
			return ()
		}
	}
}
