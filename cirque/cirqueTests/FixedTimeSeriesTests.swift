//
//  FixedTimeSeries.swift
//  cirque
//
//  Created by Ivan Milles on 2017-01-05.
//  Copyright © 2017 Rusted. All rights reserved.
//

import XCTest

class FixedTimeSeriesTests: XCTestCase {
	
	func testImmediateAveragesIntoTrend() {
		var s = FixedTimeSeries(immediateSlots: 4, trendSlots: 5, characteristicSlots: 1)
		
		// This averages 10.0/4.0 = 2.5
		s.push(1.0)
		s.push(2.0)
		s.push(3.0)
		s.push(4.0)
		
		// This averages 26.0/4.0 = 6.5
		s.push(5.0)	// Spill over
		s.push(6.0)
		s.push(7.0)
		s.push(8.0)
		
		s.push(9.0) // Spill over

		XCTAssertEqual(s.trend.buffer[0], 2.5)
		XCTAssertEqual(s.trend.buffer[1], 6.5)
	}
	
	func testTrendMaxesIntoCharacteristic() {
		var s = FixedTimeSeries(immediateSlots: 2, trendSlots: 1, characteristicSlots: 1)
		
		// This fills immediate buffer once (avg = 2.5)
		s.push(4.0)
		s.push(1.0)
		
		// This fills immediate buffer again (avg = 5.5)
		s.push(5.0)	// Spill over, overwrite
		s.push(6.0)
		
		// This fills immediate buffer again (avg = 4.0)
		s.push(5.0)	// Spill over, don't overwrite
		s.push(3.0)
		
		// Filling the trend buffer overflows into characteristic buffer
		XCTAssertEqual(s.characteristic.buffer[0], 5.5)
	}
	
	func testCharacteristicsDoesntGrow() {
		var s = FixedTimeSeries(immediateSlots: 2, trendSlots: 2, characteristicSlots: 1)
		
		s.push(6.0)
		s.push(5.0)
		s.push(4.0)
		s.push(1.0)
		s.push(2.0)
		s.push(3.0)
		s.push(6.0)
		s.push(5.0)
		s.push(4.0)
		s.push(1.0)
		s.push(2.0)
		s.push(3.0)
		
		XCTAssertEqual(s.characteristic.buffer.count, 1)
	}
}
