//
//  BestFitCircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-17.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation

struct BestFitCircle {
	var lineWidths: [(a: Double, w: Double)]
	var fitRadius: Double
	var center: Point
	
	init(around: Point, radius: Double, startAngle: Double, progress: Double, taper: Taper) {
		fitRadius = radius
		center = around
		
		let fidelity = 1.0/360.0
		let direction = taper.clockwise ? -1.0 : 1.0
		let endAngle = startAngle + progress * 2.0 * M_PI * direction
		let step = 2.0 * M_PI * fidelity * direction
		
		let arcs = stride(from: startAngle, through: endAngle, by: step)
		let widths = taper.taperWidths(angles: arcs)
		
		lineWidths = zip(arcs, widths).map { (a: $0, w: $1) }
	}
}

