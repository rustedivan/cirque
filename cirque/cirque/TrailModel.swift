//
//  TrailModel.swift
//  cirque
//
//  Created by Ivan Milles on 07/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import Darwin

struct Trail {
	var points = PointArray()
	var angles: [Double] {
		return anglesBetweenPoints()
	}
	var distances: [Double] {
		return distancesBetweenPoints()
	}
	
	mutating func addPoint(_ p: Point) {
		guard points.last == nil || points.last! != p else { return }
		points.append(p)
	}
	
	fileprivate func anglesBetweenPoints() -> [Double] {
		guard points.count > 1 else { return [] }
		
		func angleBetween(_ p1: Point, _ p2: Point) -> Double {
			return atan2(p2.y - p1.y, p2.x - p1.x)
		}
		
		let segmentAngles = points.indices.map { i -> Double in
			if i == 0 {
				return angleBetween(points[0], points[1])
			} else if i == points.count - 1 {
				return angleBetween(points[i - 1], points[i])
			} else {
				return angleBetween(points[i - 1], points[i + 1])
			}
		}
		
		return segmentAngles
	}
	
	fileprivate func distancesBetweenPoints() -> [Double] {
		guard points.count > 1 else { return [] }
		
		func distanceBetween(_ p1: Point, _ p2: Point) -> Double {
			let dP = Vector(dx: p1.x - p2.x, dy: p1.y - p2.y)
			return sqrt(dP.dx * dP.dx + dP.dy * dP.dy)
		}
		
		let segmentLengths = points.indices.map { i -> Double in
			if i == 0 {
				return distanceBetween(points[0], points[1])
			} else {
				return distanceBetween(points[i - 1], points[i])
			}
		}
		
		return segmentLengths
	}
}
