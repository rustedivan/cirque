//
//  TrailModel.swift
//  cirque
//
//  Created by Ivan Milles on 07/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import Darwin
import CoreGraphics.CGGeometry

@objc
class Trail: NSObject {
	var points: Array<CGPoint> = Array()
	
	func addPoint(p: CGPoint) {
		points.append(p)
	}
	
	// $ Bridging interface for CircleView
	func nPoints() -> Int {return points.count}
	func point(i:Int) -> CGPoint {return points[i]}
	
	func segmentAngles() -> Array<Float> {
		if points.count < 2 { return [] }
		
		func angle(p1: CGPoint, p2: CGPoint) -> Float {
			return atan2(Float(p2.y - p1.y), Float(p2.x - p1.x))	// $ Not really sure why these casts are necessary
		}
		
		var angles = Array<Float>()
		let n = points.count

		angles.append(angle(points[0], points[1]))
		for (var i = 1; i < n - 1; i++) {
			angles.append(angle(points[i - 1], points[i + 1]))
		}
		angles.append(angle(points[n - 2], points.last!))

		return angles
	}
}
