//
//  ErrorAreaModel.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-17.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation

struct ErrorArea {
	typealias ErrorBar = (a: Double, r: Double, isCap: Bool)
	var errorBars: [ErrorBar] = []
	var fitRadius: Double
	var rootAngle: Double
	var center: Point

	init(_ points: [Polar], around: Point, radius: Double, treshold: Double) {
		fitRadius = radius
		center = around
		rootAngle = points.first?.a ?? 0.0
		var insideErrorArea = false
		
		for (i, p) in points.enumerated() {
			if fabs(p.r - radius) > treshold {
				let prev = (i - 1 > points.startIndex) ? points[i - 1] : p
				
				// Cap the start of the error area
				if !insideErrorArea {
					errorBars.append((a: prev.a, r: radius, isCap: true))
					insideErrorArea = true
				}
				
				errorBars.append((a: p.a, r: p.r, isCap: false))
			} else if insideErrorArea {
				// Cap the end of the error area
				errorBars.append((a: p.a, r: radius, isCap: true))
				insideErrorArea = false
			}
		}
	}
}
