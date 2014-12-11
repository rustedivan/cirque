//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

@objc
public class Circle: NSObject {
	var segments = Trail()
	var centroid: CGPoint?
	
	func begin() {
	}
	
	func addSegment(p: CGPoint) {
		segments.addPoint(p)
	}
	
	func end() {
		centroid = calculateCentroid(segments.points)
		println("Centroid: \(centroid!.x), \(centroid!.y)")
	}
	
	func calculateCentroid(points: Array<CGPoint>) -> CGPoint {
		var c = CGPointZero
		for i in 0 ..< points.count {
			c.x += points[i].x
			c.y += points[i].y
		}
		
		c.x /= CGFloat(points.count)
		c.y /= CGFloat(points.count)
		return c
	}
	
	func polarizePoints(points: Array<CGPoint>) -> Array<(r: Float, a: Float)> {
		var polar: Array<(r: Float, a: Float)> = []

		let c = calculateCentroid(points)
		
		for i in 0 ..< points.count {
			var p = points[i]
			p.x -= c.x
			p.y -= c.y
			
			let a = atan2f(Float(p.y), Float(p.x))
			let r = sqrt(p.x * p.x + p.y * p.y)
			
			polar.append(r: Float(r), a: Float(a))
		}

		return polar
	}
	
	func calculateRoundness(points: Array<CGPoint>) -> Float {
		var polar = polarizePoints(points)
		var rHat = polar.reduce(0.0) {$0 + $1.r} / Float(polar.count)
		var aHat = polar.reduce(0.0) {$0 + ($1.r * cos($1.a))} / (2.0 * Float(polar.count))
		var bHat = polar.reduce(0.0) {$0 + ($1.r * sin($1.a))} / (2.0 * Float(polar.count))
		
		// Given samples in point_i,
		// Calculate least squares where the ith deviation is
		// dI = R_i - rHat - aHat*cos(a_i) - bHat*sin(a_i)
		// We are looking for an optimal value of R that minimizes
		
		return 0
	}
}
