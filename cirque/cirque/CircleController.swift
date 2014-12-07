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
		view.render(circle);
		
		let r = 10.0 + Float(frames) / 100.0
		let a = 0.01 * Float(frames)
		let x = CGFloat(cos(a) * r)
		let y = CGFloat(sin(a) * r)
		let p = CGPoint(x: x, y: y)
		circle.addSegment(CGPoint(x: x, y: y))
		
		frames++
	}
}
