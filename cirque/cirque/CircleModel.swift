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
		let circleFidelity: UInt = 90
		let radius: Float = 150.0
		let thickness: Float = 10.0
		let sector: Float = Float(2.0 * M_PI) / Float(circleFidelity)
		
		for (var i: UInt = 0; i < circleFidelity + 1; i++) {
			let a = Float(i) * sector
			let innerRadius = radius - thickness/2.0
			let outerRadius = radius + thickness/2.0
			
			vertices.append(cos(a) * innerRadius)
			vertices.append(sin(a) * innerRadius)
			vertices.append(cos(a) * outerRadius)
			vertices.append(sin(a) * outerRadius)
			
			indices.append(UInt(2 * i + 0))
			indices.append(UInt(2 * i + 1))
		}
	}
}
