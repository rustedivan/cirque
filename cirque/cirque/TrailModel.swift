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
	var points = PointArray()
	var angles: Array<CGFloat> = Array()
	
	func addPoint(p: CGPoint) {
		points.append(p)
		updateAngles()
	}
	
	private func updateAngles() {
		func angleBetween(p1: CGPoint, p2: CGPoint) -> CGFloat {
			return atan2(p2.y - p1.y, p2.x - p1.x)
		}
		
		let n = points.count
		if n < 2 { return }
		if (angles.count == 0) {angles.append(0.0)}

		// Add the new point
		angles.append(angleBetween(points[n - 2], points[n - 1]))
		
		// Re-align the previous point
		if n == 2 {
			angles[n - 2] = angleBetween(points[n - 2], points[n - 1])
		} else {
			angles[n - 2] = angleBetween(points[n - 3], points[n - 1])
		}
	}
	
	// $ Bridging interface for CircleView
	func nPoints() -> Int {return points.count}
	func point(i:Int) -> CGPoint {return points[i]}
}