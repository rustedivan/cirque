//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import Darwin

// $ This is only necessary because the bridging header
//   doesn't take Array<(Float, Float)>. When the renderer
//	 is in Swift, just chuck all of this stuff... [1]
@objc
class Segment {
	var angle: Float = 0.0
	var radius: Float = 0.0
	
	convenience init (a: Float, r: Float) {
		self.init()
		angle = a
		radius = r
	}
}

@objc
public class Circle: NSObject {
	var vertices: Array<Float> = Array()
	var indices: Array<UInt> = Array()
	var segments: Array<Segment> = Array()	// $ [1] ...and replace with <(Float, Float)>
	var p: Float
	
	override init() {
		p = 10.0 * Float(rand()) / Float(RAND_MAX) - 5.0
		super.init()
	}
	
	func addSegment(angle: Float, radius: Float) {
		segments.append(Segment(a: angle, r: radius))
	}
	
	func stepCircle() {
		let circleFidelity: UInt = 90
		let radius: Float = 120.0
		let sector: Float = Float(2.0 * M_PI) / Float(circleFidelity)
		
		let i = segments.count
		let a = Float(i) * sector
		let r = radius * messUpRadiusFactor(a, param: p)
		addSegment(a, radius: r)
	}
	
	private func messUpRadiusFactor(angle: Float, param: Float) -> Float {
		let t: Double = Double(angle) / (2.0 * M_PI)
		let p0 = 1.0
		let p1 = 1.0
		let m0 = Double(param)
		let m1 = Double(param)
		
		let t1 = (2.0 * t * t * t - 3.0 * t * t + 1) * p0
		let t2 = (t * t * t - 2.0 * t * t + t) * m0
		let t3 = (-2 * t * t * t + 3 * t * t) * p1
		let t4 = (t * t * t - t * t) * m1
		return Float(t1 + t2 + t3 + t4)
	}
	
	
}
