//
//  FixedTimeSeries.swift
//  cirque
//
//  Created by Ivan Milles on 2017-01-05.
//  Copyright © 2017 Rusted. All rights reserved.
//

import Foundation


struct FixedTimeSeries {
	let maxSamples: Int
	var timeSeries: [Float]
	private var storedAverage: Float
	
	init(depth: Int) {
		maxSamples = depth
		timeSeries = []
		storedAverage = 0.0
	}
	
	init(depth: Int, values: [Float]) {
		maxSamples = depth
		timeSeries = values
		storedAverage = timeSeries.reduce(0.0, +) / Float(timeSeries.count)
	}
	
	var average: Double { return Double(storedAverage) }

	mutating func add(_ v: Double) {
		let fV = Float(v)	// More compact storage
		
		if timeSeries.count >= maxSamples {
			// Take out oldest value from stored average (cancel first value, average without its count)
			storedAverage = (-timeSeries.first! + Float(timeSeries.count) * storedAverage) / Float(timeSeries.count - 1)
			timeSeries = Array(timeSeries.dropFirst())
		}

		// Update stored average with incoming value
		storedAverage = (fV + Float(timeSeries.count) * storedAverage) / Float(timeSeries.count + 1)
		timeSeries.append(fV)
	}
}

// MARK: NSCoding for structs

extension FixedTimeSeries {
	class Coding : NSObject, NSCoding {
		let fixedTimeSeries: FixedTimeSeries?
		
		init(series: FixedTimeSeries) {
			fixedTimeSeries = series
			super.init()
		}
		
		required init?(coder aDecoder: NSCoder) {
			guard let timeSeries = aDecoder.decodeObject(forKey: "samples") as? [Float] else { return nil	}
			let maxSamples = aDecoder.decodeInteger(forKey: "maxSamples")
			
			self.fixedTimeSeries = FixedTimeSeries(depth: maxSamples, values: timeSeries)
			super.init()
		}
		
		func encode(with aCoder: NSCoder) {
			guard let fixedTimeSeries = fixedTimeSeries else { return }
			aCoder.encode(fixedTimeSeries.maxSamples, forKey: "maxSamples")
			aCoder.encode(fixedTimeSeries.timeSeries, forKey: "samples")
		}
	}
}

extension FixedTimeSeries : Encodable {
	var encoded : Decodable? {
		return FixedTimeSeries.Coding(series: self)
	}
}

extension FixedTimeSeries.Coding : Decodable {
	var decoded : Encodable? {
		return fixedTimeSeries
	}
}
