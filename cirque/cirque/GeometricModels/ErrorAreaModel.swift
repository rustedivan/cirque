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
	var fit: CircleFit
	var rootAngle: Double

	// FIXME: it's pretty ugly to pass the polar array directly
	init(_ points: PolarArray, fit: CircleFit, treshold: Double) {
		self.fit = fit
		rootAngle = points.first?.a ?? 0.0
		var insideErrorArea = false
		
		for (i, p) in points.enumerated() {
			if fabs(p.r - fit.radius) > treshold {
				let prev = (i - 1 > points.startIndex) ? points[i - 1] : p
				
				// Cap the start of the error area
				if !insideErrorArea {
					errorBars.append((a: prev.a, r: fit.radius, isCap: true))
					insideErrorArea = true
				}
				
				errorBars.append((a: p.a, r: p.r, isCap: false))
			} else if insideErrorArea {
				// Cap the end of the error area
				errorBars.append((a: p.a, r: fit.radius, isCap: true))
				insideErrorArea = false
			}
		}
	}
}
