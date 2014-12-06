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
	
	override init() {
		let circleFidelity: UInt = 360
		let radius: Float = 100.0
		let sector: Float = Float(2.0 * M_PI) / Float(circleFidelity)
		
		for (var i: UInt = 0; i < circleFidelity; i++) {
			let a = Float(i) * sector
			vertices.append(cos(a) * radius)
			vertices.append(sin(a) * radius)
			indices.append(UInt(i))
		}
	}
}
