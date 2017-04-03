//
//  CircleController.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

class CircleController {
	var trail = Trail()
	
	var analysisTimestamp = Date()
	var analysisRunning = false
		
	func beginNewCircle(_ p: Point) {
		trail.addPoint(p)
	}
	
	func addSegment(_ p: Point) {
		guard trail.distanceFromEnd(p) > Trail.segmentFilterDistance else {
			return
		}
		
		trail.addPoint(p)
	}

	func endCircle(_ p: Point) -> Trail {
		trail.addPoint(p)
		return trail
	}
}
