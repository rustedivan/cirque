//
//  FixedTimeSeries.swift
//  cirque
//
//  Created by Ivan Milles on 2017-01-05.
//  Copyright © 2017 Rusted. All rights reserved.
//

import XCTest

class FixedTimeSeriesTests: XCTestCase {
	func testMaintainsCumulativeAverage() {
		var series = FixedTimeSeries(depth: 5)
		
		series.add(1.0)
		XCTAssertEqualWithAccuracy(series.average, 1.0, accuracy: 0.01)
		series.add(2.0)
		XCTAssertEqualWithAccuracy(series.average, 1.5, accuracy: 0.01)
		series.add(3.0)
		series.add(4.0)
		series.add(5.0)
		
		// Updated, stored average
		XCTAssertEqualWithAccuracy(series.average, 3.0, accuracy: 0.01)
		
		// Drop first when at capacity
		series.add(6.0)
		XCTAssertEqualWithAccuracy(series.average, 4.0, accuracy: 0.01)
	}
	
	func testLinearRegression() {
		var growSeries = FixedTimeSeries(depth: 5)
		growSeries.add(1.0)
		growSeries.add(-2.0)
		growSeries.add(3.0)
		growSeries.add(4.0)
		growSeries.add(5.0)
		let increasingTrend = linearTrend(growSeries.timeSeries)
		XCTAssertGreaterThan(increasingTrend, 0.0)
		
		var shrinkSeries = FixedTimeSeries(depth: 5)
		shrinkSeries.add(1.0)
		shrinkSeries.add(2.0)
		shrinkSeries.add(-3.0)
		shrinkSeries.add(-4.0)
		shrinkSeries.add(-5.0)
		let decreasingTrend = linearTrend(shrinkSeries.timeSeries)
		XCTAssertLessThan(decreasingTrend, 0.0)
		
		var stableSeries = FixedTimeSeries(depth: 5)
		stableSeries.add(2.0)
		stableSeries.add(-2.0)
		stableSeries.add(2.0)
		stableSeries.add(-2.0)
		stableSeries.add(2.0)
		let stableTrend = linearTrend(stableSeries.timeSeries)
		XCTAssertEqualWithAccuracy(stableTrend, 0.0, accuracy: 0.01)
	}
}
