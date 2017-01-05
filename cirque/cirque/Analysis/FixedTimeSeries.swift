//
//  FixedTimeSeries.swift
//  cirque
//
//  Created by Ivan Milles on 2017-01-05.
//  Copyright © 2017 Rusted. All rights reserved.
//

import Foundation


struct FixedTimeSeries {
	struct SpillBuffer {
		let capacity: Int
		var buffer: [Double] = []
		private var writes: Int = 0
		
		init(capacity size: Int) {
			capacity = size
		}
		
		mutating func append(_ value: Double) {
			buffer.append(value)
			if buffer.count > capacity {
				buffer.removeFirst()
			}
			writes += 1
		}
		
		mutating func flush() {
			writes = 0
		}
		
		var shouldFlush: Bool {
			return writes >= capacity
		}
	}

	var immediate : SpillBuffer
	var trend : SpillBuffer
	var characteristic : SpillBuffer
	
	init(immediateSlots: Int, trendSlots: Int, characteristicSlots: Int) {
		characteristic = SpillBuffer(capacity: characteristicSlots)
		trend = SpillBuffer(capacity: immediateSlots)
		immediate = SpillBuffer(capacity: immediateSlots)
	}
	
	mutating func push(_ value: Double) {
		// The immediate buffer spills its average into the trend buffer
		immediate.append(value)
		if immediate.shouldFlush {
			trend.append(immediateAverage)
			immediate.flush()
		}
		
		if trend.shouldFlush {
			characteristic.append(bestTrend)
			trend.flush()
		}
		
		if characteristic.shouldFlush {
			// Do nothing
		}
	}
	
	private var immediateAverage: Double {
		return immediate.buffer.reduce(0.0, +) / Double(immediate.buffer.count)
	}
	
	private var bestTrend: Double {
		return trend.buffer.max() ?? 0.0
	}
}
