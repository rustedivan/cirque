//
//  GeometryHelpers.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-13.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation

struct Taper {
	let taperRatio: Double
	let clockwise: Bool
	
	func taperWidths(angles angleSequence: StrideThrough<Double>) -> [Double] {
		let angles = angleSequence.map { $0 }
		guard angles.count >= 2 else {
			return [1.0]
		}
		
		let taperStart = Int((1.0 - taperRatio) * Double(angles.count))
		let taperEnd = angles.endIndex - 1
		let taperRange = Range(uncheckedBounds: (lower: angles[taperStart],
		                                         upper: angles[taperEnd]))
		let map = angles.enumerated().map { (i, a) -> Double in
			if i > taperStart {
				return taper(angle: a, inRange: taperRange)
			} else {
				return 1.0
			}
		}
		return map
	}
	
	func taper(angle a: Double, inRange range: Range<Double>) -> Double {
		let taperWidth = range.upperBound - range.lowerBound
		let taperIndex = a - range.lowerBound
		return 1.0 - (taperIndex / taperWidth)
	}
}
