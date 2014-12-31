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
		
//		circle.dumpAsSwiftArray()
		
		let fit = CircleFitter().fitCenterAndRadius(circle.segments.points)
		let polar = circle.polarizePoints(circle.segments.points, around: fit.center)
		let analyser = TrailAnalyser(points: polar)
		
		return Float(analyser.strokeCongestion().angle)
	}
}
