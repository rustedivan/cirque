//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

typealias Point = CGPoint
typealias PointArray = Array<Point>
typealias Polar = (r: CGFloat, a: CGFloat)
typealias PolarArray = Array<Polar>

@objc
public class Circle: NSObject {
	var segments = Trail()
	
	func begin() {
	}
	
	func addSegment(p: CGPoint) {
		segments.addPoint(p)
	}
	
	func end() {
	}
	
	func calculateFitError() -> Float {
		let cf = CircleFitter()
		let fit = cf.fitCenterAndRadius(segments.points)
		let polarized = polarizePoints(segments.points, around: fit.center)
		let deviations = deviationsFromFit(polarPoints: polarized, radius: fit.radius)
		let rmsError = sqrt(deviations.reduce(0.0) {$0 + $1 * $1} / CGFloat(deviations.count))
		return Float(rmsError)
	}
	
	func polarizePoints(points: PointArray, around c: CGPoint) -> PolarArray {
		var polar: PolarArray = []
		
		for i in 0 ..< points.count {
			var p = points[i]
			p.x -= c.x
			p.y -= c.y
			
			let a = CGFloat(atan2f(Float(p.y), Float(p.x)))
			let r = sqrt(p.x * p.x + p.y * p.y)
			
			polar.append((r: r, a: a))
		}
		
		return polar
	}
	
	func deviationsFromFit(polarPoints points: PolarArray, radius: CGFloat) -> Array<CGFloat> {
		var deviations = [CGFloat]()
		for p in points {
			deviations.append(p.r - radius)
		}
		return deviations
	}
}
