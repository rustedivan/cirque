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

@objc
public class Circle: NSObject {
	var segments = Trail()
	
	func begin() {
	}
	
	func addSegment(p: CGPoint) {
		segments.addPoint(p)
	}
	
	func end() {
		let cf = CircleFitter()
		let fit = cf.fitCenterAndRadius(segments.points)
		
		println("Fitted circle: \(fit.center.x), \(fit.center.y) @ \(fit.radius)")
	}
}
