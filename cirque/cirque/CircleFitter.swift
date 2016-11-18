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

typealias CircleFit = (center: Point, radius: CGFloat)
typealias CircleFitCallback = (CircleFit) -> ()

struct CircleFitter {
	
	static func fitCenterAndRadius(_ points: PointArray) -> CircleFit {
		// Transform into
		let p = centerPoints(points)
		
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
		
		let c = centroid(points)
		
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
		let alpha = x * x + y * y + (sUU + sVV) / CGFloat(p.count)
		
		return (CGPoint(x: x + c.x, y: y + c.y), sqrt(alpha)) as CircleFit
	}
	
	static func centroid(_ points: PointArray) -> Point {
		var c = points.reduce(CGPoint.zero) {CGPoint(x: $0.x + $1.x, y: $0.y + $1.y)}
		c.x /= CGFloat(points.count)
		c.y /= CGFloat(points.count)
		return c
	}
	
	static func centerPoints(_ points: PointArray) -> PointArray {
		let on = centroid(points)
		return points.map{CGPoint(x: $0.x - on.x, y: $0.y - on.y)}
	}
	
	static func sumUU(_ points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.x)}
	}

	static func sumUV(_ points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.y)}
	}

	static func sumVV(_ points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.y * $1.y)}
	}

	static func sumUUU(_ points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.x * $1.x)}
	}

	static func sumVVV(_ points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.y * $1.y * $1.y)}
	}

	static func sumUUV(_ points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.x * $1.y)}
	}

	static func sumUVV(_ points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.y * $1.y)}
	}
}
