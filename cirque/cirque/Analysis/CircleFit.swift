//
//  CircleFitter.swift
//  cirque
//
//  Created by Ivan Milles on 13/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

// Based on least-square fitting from
// http://www.dtcenter.org/met/users/docs/write_ups/circle_fit.pdf

// $ Move this code onto Surge library

typealias CircleFit = (center: Point, radius: Double)

extension TrailAnalyser {
	
	static func fitCenterAndRadius(_ trail: Trail) -> CircleFit {
		// Transform into
		let (c, p) = centerPoints(trail)
		
		let sUU = sumUU(p)
		let sUV = sumUV(p)
		let sVV = sumVV(p)
		let sVVV = sumVVV(p)
		let sUUU = sumUUU(p)
		let sUUV = sumUUV(p)
		let sUVV = sumUVV(p)
		
		// Matrix A
		let A11 = sUU
		let A12 = sUV
		let A21 = sUV
		let A22 = sVV
		
		// Determinant of A
		let detA = A11*A22 - A12*A21
		if (detA == 0.0) {
			return CircleFit(center: c, radius: 0.0)
		}
		
		// Vector b
		let b1 = (sUUU + sUVV) / 2.0
		let b2 = (sVVV + sUUV) / 2.0
		
		// Matrix At
		let At11 =  A22 / detA
		let At12 = -A12 / detA
		let At21 = -A21 / detA
		let At22 =  A11 / detA
		
		// Solve x = At * b
		let x = At11 * b1 + At12 * b2
		let y = At21 * b1 + At22 * b2
		
		// Solve for radius
		let alpha = x * x + y * y + (sUU + sVV) / Double(p.count)
		
		return (Point(x: x + c.x, y: y + c.y), sqrt(alpha)) as CircleFit
	}
	
	static func centroid(_ trail: Trail) -> Point {
		var c = trail.reduce(zeroPoint) {
			Point(x: $0.x + $1.x, y: $0.y + $1.y)
		}
		c.x /= Double(trail.count)
		c.y /= Double(trail.count)
		return c
	}
	
	static func centerPoints(_ trail: Trail) -> (Point, [Point]) {
		let on = centroid(trail)
		return (on, trail.map{ Point(x: $0.x - on.x, y: $0.y - on.y) } )
	}
}

// MARK: Sum combinations
func sumUU(_ points: [Point]) -> Double {
	return points.reduce(0.0) {$0 + ($1.x * $1.x)}
}

func sumUV(_ points: [Point]) -> Double {
	return points.reduce(0.0) {$0 + ($1.x * $1.y)}
}

func sumVV(_ points: [Point]) -> Double {
	return points.reduce(0.0) {$0 + ($1.y * $1.y)}
}

func sumUUU(_ points: [Point]) -> Double {
	return points.reduce(0.0) {$0 + ($1.x * $1.x * $1.x)}
}

func sumVVV(_ points: [Point]) -> Double {
	return points.reduce(0.0) {$0 + ($1.y * $1.y * $1.y)}
}

func sumUUV(_ points: [Point]) -> Double {
	return points.reduce(0.0) {$0 + ($1.x * $1.x * $1.y)}
}

func sumUVV(_ points: [Point]) -> Double {
	return points.reduce(0.0) {$0 + ($1.x * $1.y * $1.y)}
}

// MARK: Regression
func linearTrend(_ values: [Double]) -> Double {
	let indices = [Int](0 ..< values.count)
	let n = Double(values.count)
	
	let sumX = Double(indices.reduce(0, +))
	let sumY = values.reduce(0.0, +)
	let avgX = sumX / n
	let avgY = sumY / n
	
	let sumXX = indices.reduce(0.0) { $0 + Double($1 * $1) }
	let sumXY = zip(indices, values).reduce(0.0) { $0 + Double($1.0) * $1.1 }
	
	let numerator = (sumXY / n) - (avgX * avgY)
	let denominator = ((sumXX/n) - (avgX * avgX))
	let regression = numerator / denominator
	
	return regression
}

// $ No idea how to make this generic. No protocol for floating-point math, only IntegerArithmetic.
func linearTrend(_ values: [Float]) -> Double {
	let indices = [Int](0 ..< values.count)
	let n = Float(values.count)
	
	let sumX = Float(indices.reduce(0, +))
	let sumY = values.reduce(0.0, +)
	let avgX = sumX / n
	let avgY = sumY / n
	
	let sumXX = indices.reduce(0.0) { $0 + Float($1 * $1) }
	let sumXY = zip(indices, values).reduce(0.0) { $0 + Float($1.0) * $1.1 }
	
	let numerator = (sumXY / n) - (avgX * avgY)
	let denominator = ((sumXX/n) - (avgX * avgX))
	let regression = numerator / denominator
	
	return Double(regression)
}
