//
//  CircleController.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation

class CircleController: NSObject {
	var circle: Circle = Circle()
	var frames = 0
	
	func draw(view: CircleView) {
		view.render(circle)
	}
	
	func beginNewCircle(p: CGPoint) {
		circle.begin()
		circle.addSegment(p)
	}
	
	func addSegment(p: CGPoint) {
		circle.addSegment(p)
	}

	func endCircle(p: CGPoint) -> Float {
		circle.addSegment(p)
		circle.end()
		return circle.calculateFitError()
	}
}
