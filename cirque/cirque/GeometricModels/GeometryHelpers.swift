//
//  GeometryHelpers.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-13.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry
import simd

typealias Point = (x: Double, y: Double)
typealias Vector = (dx: Double, dy: Double)
typealias PointArray = [Point]
typealias Polar = (r: Double, a: Double)
typealias PolarArray = [Polar]
typealias AngleBucket = (points: PolarArray, angle: Double)

let zeroPoint = Point(x: 0.0, y: 0.0)

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

func polarize(_ points: Trail, around c: Point) -> PolarArray {
	return points.map { (p: Point) -> Polar in
		let x = p.x - c.x
		let y = p.y - c.y
		
		// UIView's Y axis is flipped, 
		// so the angle must be negated to correct
		var a = -atan2(y, x)
		let r = sqrt(x * x + y * y)
	
		if a < 0.0 { a += M_PI * 2.0 }
		if a > 2.0 * M_PI { a -= M_PI * 2.0 }

		return Polar(r: r, a: a)
	}
}

func angleDistances(_ points: PolarArray) -> [Double] {
	var deltaA: [Double] = []
	for i in 0 ..< points.count - 1 {
		let prev = points[i].a
		let next = points[i + 1].a
		var d = next - prev
		if d > M_PI { d -= 2.0 * M_PI }
		if d < -M_PI { d += 2.0 * M_PI }
		deltaA.append(d)
	}
	return deltaA
}

func ortho2d(l: CGFloat, r: CGFloat, b: CGFloat, t: CGFloat, n: CGFloat, f: CGFloat) -> matrix_float4x4 {
	let width = 1.0 / (r - l)
	let height = 1.0 / (t - b)
	let depth = 1.0 / (f - n)
	
	var p = float4(0.0)
	var q = float4(0.0)
	var r = float4(0.0)
	var s = float4(0.0)
	
	p.x = 2.0 * Float(width)
	q.y = 2.0 * Float(height)
	r.z = Float(depth)
	s.z = Float(-n * depth)
	s.w = 1.0
	
	return matrix_float4x4(columns: (p, q, r, s))
}

extension CGPoint {
	init(point: Point) {
		self.init(x: CGFloat(point.x), y: CGFloat(point.y))
	}
}
