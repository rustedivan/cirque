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

func polarize(_ points: PointArray, around c: Point) -> PolarArray {
	var polar: PolarArray = []
	
	for i in 0 ..< points.count {
		var p = points[i]
		p.x -= c.x
		p.y -= c.y
		
		let a = atan2(p.y, p.x)
		let r = sqrt(p.x * p.x + p.y * p.y)
		
		// UIView's Y axis is flipped, so the angle must be inverted to correct
		polar.append((r: r, a: -a))
	}
	
	// Normalize angles
	for i in 0 ..< polar.count {
		if polar[i].a < 0.0 { polar[i].a += M_PI * 2.0 }
		if polar[i].a > 2.0 * M_PI { polar[i].a -= M_PI * 2.0 }
	}
	
	return polar
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
