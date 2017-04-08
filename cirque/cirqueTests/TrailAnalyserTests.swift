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
		let realGoodTrail = Trail(withPoints: realGoodCircleTrail)
		let justGoodTrail = Trail(withPoints: justGoodCircleTrail)
		let justBadTrail = Trail(withPoints: justBadCircleTrail)
		let realBadTrail = Trail(withPoints: realBadCircleTrail)

		let realGood = TrailAnalyser(trail: realGoodTrail, bucketCount: 8).runAnalysis().circularityScore
		let justGood = TrailAnalyser(trail: justGoodTrail, bucketCount: 8).runAnalysis().circularityScore
		let justBad = TrailAnalyser(trail: justBadTrail, bucketCount: 8).runAnalysis().circularityScore
		let realBad = TrailAnalyser(trail: realBadTrail, bucketCount: 8).runAnalysis().circularityScore

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
		let unevenTrail = Trail(withPoints: unevenStrokeTrail)
		let evenTrail = Trail(withPoints: evenStrokeTrail)
		let perfectTrail = Trail(withPoints: perfectStrokeTrail)
		
		let bad = TrailAnalyser(trail: unevenTrail, bucketCount: 8).runAnalysis().strokeEvenness
		let good = TrailAnalyser(trail: evenTrail, bucketCount: 8).runAnalysis().strokeEvenness
		let perfect = TrailAnalyser(trail: perfectTrail, bucketCount: 8).runAnalysis().strokeEvenness
		
		XCTAssertGreaterThan(bad, 0.0, "This stroke should not be perfect")
		XCTAssertGreaterThan(good, 0.0, "This stroke should not be perfect")
		XCTAssertLessThan(good, bad, "Uneven stroke should have higher error than even stroke")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect stroke should snap error to zero")
	}
	
	/* Congestion direction:	given all angular displacements, calc exponential sliding average
														to filter the data down to 8 cardinal points. Find max-deviation.
	*/
	func testFindStrokeCongestionDirection() {
		let congestionDown = Trail(withPoints: congestedDown)
		let congestionUpLeft = Trail(withPoints: congestedUpperLeft)
		let congestionD = TrailAnalyser(trail: congestionDown, bucketCount: 8).runAnalysis().strokeCongestion
		let congestionUL = TrailAnalyser(trail: congestionUpLeft, bucketCount: 8).runAnalysis().strokeCongestion
		
		XCTAssertGreaterThan(congestionD.peak, 0.0, "Did not calculate congestion")
		XCTAssertEqualWithAccuracy(congestionD.angle, 3.0 * .pi/2.0, accuracy: .pi/4.0, "Did not direct congestion")
		XCTAssertGreaterThan(congestionUL.peak, 0.0, "Did not calculate congestion")
		XCTAssertEqualWithAccuracy(congestionUL.angle, 3.0 * .pi/4.0, accuracy: .pi/4.0, "Did not direct congestion")
	}
	
	/* Radial deviations: given a fit circle, calculate the residial vector of radial samples.
	*/
//	func testCalculateRadialDeviations() {
//		let points: [Polar] = [	(a: 0.0, r: 100.0),
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
		let bumpInULTrail = Trail(withPoints: upperLeftBumpIn)
		let bumpInDTrail = Trail(withPoints: downBumpIn)
		let flatRightTrail = Trail(withPoints: flatBumpRight)
		let noBumpTrail = Trail(withPoints: almostNoBump)
		
		let bumpInUL = TrailAnalyser(trail: bumpInULTrail, bucketCount: 36).runAnalysis().radialDeviation
		let bumpInD = TrailAnalyser(trail: bumpInDTrail, bucketCount: 36).runAnalysis().radialDeviation
		let flatRight = TrailAnalyser(trail: flatRightTrail, bucketCount: 36).runAnalysis().radialDeviation
		let noBump = TrailAnalyser(trail: noBumpTrail, bucketCount: 36).runAnalysis().radialDeviation
		
		XCTAssertLessThan(bumpInUL.peak, 0.0, "Did not calculate deviation")
		XCTAssertEqualWithAccuracy(bumpInUL.angle, .pi/2.0, accuracy: 0.30, "Did not find deviation in Q2 bucket")

		XCTAssertLessThan(bumpInD.peak, 0.0, "Did not calculate deviation")
		XCTAssertEqualWithAccuracy(bumpInD.angle, 6.0 * .pi/4.0, accuracy: 0.30, "Did not find deviation")

		XCTAssertLessThan(flatRight.peak, 0.0, "Did not calculate deviation")
		XCTAssertEqualWithAccuracy(flatRight.angle, 0.0, accuracy: 0.30, "Did not find deviation")

		XCTAssertEqual(noBump.peak, 0.0, "Did not calculate deviation")
	}

	/* Radial deviation: given all relative radial displacements, calculate the RMS of them.
	*/
	func testFindRadialFitness() {
		let bumpyTrail = Trail(withPoints: bumpyCircleTrail)
		let roundTrail = Trail(withPoints: roundCircleTrail)
		let perfectTrail = Trail(withPoints: perfectCircleTrail)
		
		let bad = TrailAnalyser(trail: bumpyTrail, bucketCount: 8).runAnalysis().radialFitness
		let good = TrailAnalyser(trail: roundTrail, bucketCount: 8).runAnalysis().radialFitness
		let perfect = TrailAnalyser(trail: perfectTrail, bucketCount: 8).runAnalysis().radialFitness
		
		XCTAssertLessThan(good, bad, "Uneven circle should have higher error than even stroke")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect circle should snap error to zero")
		
		let largeBadTrailScaled = bumpyCircleTrail.map{TestPoint($0.0 * 100.0, $0.1 * 100.0)}
		let largeBadTrail = Trail(withPoints: largeBadTrailScaled)
		let largeBad = TrailAnalyser(trail: largeBadTrail, bucketCount: 8).runAnalysis().radialFitness
		XCTAssertEqualWithAccuracy(largeBad, bad, accuracy: 0.01, "Scaling the circle shouldn't cause larger error")
	}
	
	/* Report whether the RMS of the last 1/4 of the circle is significantly tighter
		 or looser than the first 1/4.
	*/
	func testFindRadialContractionOrExpansion() {
		let contractingTrail = Trail(withPoints: radialContractionTrail)
		let expandingTrail = Trail(withPoints: radialExpansionTrail)
		let perfectTrail = Trail(withPoints: perfectContractionTrail)
		
		let contraction = TrailAnalyser(trail: contractingTrail, bucketCount: 8).runAnalysis().radialContraction
		let expansion = TrailAnalyser(trail: expandingTrail, bucketCount: 8).runAnalysis().radialContraction
		let perfect = TrailAnalyser(trail: perfectTrail, bucketCount: 8).runAnalysis().radialContraction
		
		XCTAssertLessThan(contraction, 0.0, "Contracting circle should be negative")
		XCTAssertGreaterThan(expansion, 0.0, "Expanding circle should be positive")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect circle should snap error to zero")
	}
	
	/* Measure the distance in pixels between the start and end caps in absolute distance.
		 (Making the caps line up isn't significantly harder for large circles.)
		 Snap to zero if the distance is less than the width of the stroke.
	*/

	func testFindStartEndCapsSeparation() {
		let distantCapsTrail = Trail(withPoints: distantCaps)
		let veryDistantCapsTrail = Trail(withPoints: veryDistantCaps)
		let perfectTrail = Trail(withPoints: perfectCaps)
		
		let distant = TrailAnalyser(trail: distantCapsTrail, bucketCount: 8).runAnalysis().endCapsSeparation
		let veryDistant = TrailAnalyser(trail: veryDistantCapsTrail, bucketCount: 8).runAnalysis().endCapsSeparation
		let perfect = TrailAnalyser(trail: perfectTrail, bucketCount: 8).runAnalysis().endCapsSeparation
		
		XCTAssertGreaterThan(veryDistant, distant, "More distant caps should be a larger error")
		XCTAssertEqual(perfect, 0.0, "Close-to-perfect end caps should snap error to zero")
	}
	
	func testShouldRejectNonClosedCircle() {
		let notClosedTrail = Trail(withPoints: notClosed)
		let reject = TrailAnalyser(trail: notClosedTrail, bucketCount: 8).runAnalysis().isCircle
		
		XCTAssertFalse(reject, "Nonclosed circle should be rejected")
	}

	func testShouldRejectNotEvenCloseToCircle() {
		let squareTrail = Trail(withPoints: square)
		let eightTrail = Trail(withPoints: eight)
		let reject1 = TrailAnalyser(trail: squareTrail, bucketCount: 8).runAnalysis()
		let reject2 = TrailAnalyser(trail: eightTrail, bucketCount: 8).runAnalysis()
		
		XCTAssertFalse(reject1.isCircle, "Nonround circle should be rejected")
		XCTAssertFalse(reject2.isCircle, "Nonround circle should be rejected")
	}
	
	func testShouldRejectSegments() {
		let lineSegmentTrail = Trail(withPoints: lineSegment)
		let arcSegmentTrail = Trail(withPoints: arcSegment)
		let reject1 = TrailAnalyser(trail: lineSegmentTrail, bucketCount: 8).runAnalysis()
		let reject2 = TrailAnalyser(trail: arcSegmentTrail, bucketCount: 8).runAnalysis()
		
		XCTAssertFalse(reject1.isCircle, "Noncomplete circle should be rejected")
		XCTAssertFalse(reject2.isCircle, "Noncomplete circle should be rejected")
	}
	
	func testShouldAcceptHonestCircle() {
		let circleTrail = Trail(withPoints: properCircle)
		let accept = TrailAnalyser(trail: circleTrail, bucketCount: 8).runAnalysis()
		
		XCTAssertTrue(accept.isCircle, "Complete circle should be accepted")
	}
	
	func testShouldCalculateDirection() {
		let cwTrail = Trail(withPoints: clockwiseCircle)
		let cwAnalysis = TrailAnalyser(trail: cwTrail, bucketCount: 8).runAnalysis()
		
		let ccwTrail = Trail(withPoints: counterClockwiseCircle)
		let ccwAnalysis = TrailAnalyser(trail: ccwTrail, bucketCount: 8).runAnalysis()
		
		XCTAssertTrue(cwAnalysis.isClockwise)
		XCTAssertFalse(ccwAnalysis.isClockwise)
	}
	
	func testCircleShouldBinAngles() {
		let t = Trail(withPoints: binTestCircle)
		let p = polarize(t, around: zeroPoint)
		let buckets = TrailAnalyser.binPointsByAngle(p, intoBuckets: 4)
		
		XCTAssertEqual(buckets.count, 4, "Wrong number of buckets")
		
		XCTAssertEqual(buckets[0].points.count, 6, "Wrong number of points in right-bucket")
		XCTAssertEqual(buckets[1].points.count, 5, "Wrong number of points in up-bucket")
		XCTAssertEqual(buckets[2].points.count, 4, "Wrong number of points in left-bucket")
		XCTAssertEqual(buckets[3].points.count, 3, "Wrong number of points in down-bucket")
		
		XCTAssertEqualWithAccuracy(buckets[0].angle, 0.0, accuracy: 0.01, "Bucket 0 in wrong direction")
		XCTAssertEqualWithAccuracy(buckets[1].angle, .pi/2.0, accuracy: 0.01, "Bucket 1 in wrong direction")
		XCTAssertEqualWithAccuracy(buckets[2].angle, .pi, accuracy: 0.01, "Bucket 2 in wrong direction")
		XCTAssertEqualWithAccuracy(buckets[3].angle, 3.0 * .pi/2.0, accuracy: 0.01, "Bucket 3 in wrong direction")
	}
	
	func testShouldCalculateCentroid() {
		let t = Trail(withPoints: circleFitPoints)
		let c = TrailAnalyser.centroid(t)
		XCTAssertEqualWithAccuracy(c.x, 1.50, accuracy: 0.01, "Centroid not calculated correctly")
		XCTAssertEqualWithAccuracy(c.y, 3.25, accuracy: 0.01, "Centroid not calculated correctly")
	}
	
	func testShouldCalculateUVSpace() {
		let t = Trail(withPoints: circleFitPoints)
		let (_, uv) = TrailAnalyser.centerPoints(t)
		
		XCTAssertEqualWithAccuracy(uv[0].x, -1.50, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[0].y, -3.25, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[1].x, -1.00, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[1].y, -3.00, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[2].x, -0.50, accuracy: 0.01, "Centering not done correctly")
		XCTAssertEqualWithAccuracy(uv[2].y, -2.25, accuracy: 0.01, "Centering not done correctly")
	}
	
	func testShouldCalculateSums() {
		let t = Trail(withPoints: circleFitPoints)
		let (_, uv) = TrailAnalyser.centerPoints(t)
		
		XCTAssertEqualWithAccuracy(sumUU(uv), 7.00, accuracy: 0.01, "sUU not calculated correctly")
		XCTAssertEqualWithAccuracy(sumUV(uv), 21.00, accuracy: 0.01, "sUV not calculated correctly")
		XCTAssertEqualWithAccuracy(sumVV(uv), 68.25, accuracy: 0.01, "sVV not calculated correctly")
		XCTAssertEqualWithAccuracy(sumUUU(uv),	0.00, accuracy: 0.01, "sUUU not calculated correctly")
		XCTAssertEqualWithAccuracy(sumVVV(uv),	143.81, accuracy: 0.01, "sVVV not calculated correctly")
		XCTAssertEqualWithAccuracy(sumUVV(uv),	31.50, accuracy: 0.01, "sUVV not calculated correctly")
		XCTAssertEqualWithAccuracy(sumUUV(uv),	5.25, accuracy: 0.01, "sVUU not calculated correctly")
	}
	
	func testShouldFitNewCenterAndRadius() {
		let t = Trail(withPoints: circleFitPoints)
		let newCenter = TrailAnalyser.fitCenterAndRadius(t)
		XCTAssertEqualWithAccuracy(newCenter.center.x, -11.84, accuracy: 0.01, "Center point not fitted correctly")
		XCTAssertEqualWithAccuracy(newCenter.center.y, 8.45, accuracy: 0.01, "Center point not fitted correctly")
		XCTAssertEqualWithAccuracy(newCenter.radius, 14.69, accuracy: 0.01, "Radius not fitter correctly")
	}
	
	func testCircleFitSpeed() {
		var p = Array<Point>()
		for i in 0...10000 {
			let a = Point(x: Double(i) * 2.0, y: Double(i) * 3.0)
			p.append(a)
		}
		
		self.measure() {
			let _ = TrailAnalyser.fitCenterAndRadius(Trail(withPoints: p))
			return ()
		}
	}
	
	func testTrailAnalysisPerformance() {
		let testTrail = Trail(withPoints: eight)
		self.measure() {
			let _ = TrailAnalyser(trail: testTrail, bucketCount: 8)
			return ()
		}
	}
}
