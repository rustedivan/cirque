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

func polarize(_ points: PointArray, around c: Point) -> PolarArray {
	var polar: PolarArray = []
	
	for i in 0 ..< points.count {
		var p = points[i]
		p.x -= c.x
		p.y -= c.y
		
		let a = atan2(p.y, p.x)
		let r = sqrt(p.x * p.x + p.y * p.y)
		
		polar.append((r: r, a: a))
	}
	
	// Normalize angles
	for i in 0 ..< polar.count {
		if polar[i].a < 0.0 { polar[i].a += M_PI * 2.0 }
		if polar[i].a > 2.0 * M_PI { polar[i].a -= M_PI * 2.0 }
	}
	
	return polar
}
