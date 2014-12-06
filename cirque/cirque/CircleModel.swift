//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import Darwin

@objc
public class Circle: NSObject {
	public var vertices: Array<Float> = Array()
	public var indices: Array<UInt> = Array()
	var p: Float
	
	override init() {
		p = 10.0 * Float(rand()) / Float(RAND_MAX) - 5.0
		super.init()
	}
	
	func stepCircle() {
		let circleFidelity: UInt = 90
		let radius: Float = 120.0
		let thickness: Float = 10.0
		let sector: Float = Float(2.0 * M_PI) / Float(circleFidelity)
		
//		for (var i: UInt = 0; i < circleFidelity + 1; i++) {
		let i = indices.count / 2
		let a = Float(i) * sector
		let r = radius * messUpRadiusFactor(a, param: p)
		let innerRadius = r - thickness/2.0
		let outerRadius = r + thickness/2.0
		
		vertices.append(cos(a) * innerRadius)
		vertices.append(sin(a) * innerRadius)
		vertices.append(cos(a) * outerRadius)
		vertices.append(sin(a) * outerRadius)
		
		indices.append(UInt(2 * i + 0))
		indices.append(UInt(2 * i + 1))
//		}
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
