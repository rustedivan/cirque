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
typealias CircleFitCallback = (CircleFit) -> ()

struct CircleFitter {
	
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
	
	static func centerPoints(_ trail: Trail) -> (Point, PointArray) {
		let on = centroid(trail)
		return (on, trail.map{ Point(x: $0.x - on.x, y: $0.y - on.y) } )
	}
	
	static func sumUU(_ points: PointArray) -> Double {
		return points.reduce(0.0) {$0 + ($1.x * $1.x)}
	}

	static func sumUV(_ points: PointArray) -> Double {
		return points.reduce(0.0) {$0 + ($1.x * $1.y)}
	}

	static func sumVV(_ points: PointArray) -> Double {
		return points.reduce(0.0) {$0 + ($1.y * $1.y)}
	}

	static func sumUUU(_ points: PointArray) -> Double {
		return points.reduce(0.0) {$0 + ($1.x * $1.x * $1.x)}
	}

	static func sumVVV(_ points: PointArray) -> Double {
		return points.reduce(0.0) {$0 + ($1.y * $1.y * $1.y)}
	}

	static func sumUUV(_ points: PointArray) -> Double {
		return points.reduce(0.0) {$0 + ($1.x * $1.x * $1.y)}
	}

	static func sumUVV(_ points: PointArray) -> Double {
		return points.reduce(0.0) {$0 + ($1.x * $1.y * $1.y)}
	}
}
