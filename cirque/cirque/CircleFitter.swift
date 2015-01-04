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
typealias CircleFitCallback = (CircleFit?) -> ()

class CircleFitter {
	
	func fitCenterAndRadius(points: PointArray) -> CircleFit? {
		// Transform into
		let centroid = calculateCentroid(points)
		let p = centerPoints(points, on: centroid)
		
		let sUU = calcSumUU(p)
		let sUV = calcSumUV(p)
		let sVV = calcSumVV(p)
		let sVVV = calcSumVVV(p)
		let sUUU = calcSumUUU(p)
		let sUUV = calcSumUUV(p)
		let sUVV = calcSumUVV(p)
		
		// Matrix A
		let A11 = sUU
		let A12 = sUV
		let A21 = sUV
		let A22 = sVV
		
		// Determinant of A
		let detA = A11*A22 - A12*A21
		if (detA == 0.0) {return nil}
		
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
		
		return (CGPointMake(x + centroid.x, y + centroid.y), sqrt(alpha)) as CircleFit
	}
	
	func calculateCentroid(points: PointArray) -> Point {
		var c = points.reduce(CGPointZero) {CGPointMake($0.x + $1.x, $0.y + $1.y)}
		c.x /= CGFloat(points.count)
		c.y /= CGFloat(points.count)
		return c
	}
	
	func centerPoints(points: PointArray, on: Point) -> PointArray {
		return points.map{CGPointMake($0.x - on.x, $0.y - on.y)}
	}
	
	func calcSumUU(points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.x)}
	}

	func calcSumUV(points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.y)}
	}

	func calcSumVV(points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.y * $1.y)}
	}

	func calcSumUUU(points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.x * $1.x)}
	}

	func calcSumVVV(points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.y * $1.y * $1.y)}
	}

	func calcSumUUV(points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.x * $1.y)}
	}

	func calcSumUVV(points: PointArray) -> CGFloat {
		return points.reduce(0.0) {$0 + ($1.x * $1.y * $1.y)}
	}
}