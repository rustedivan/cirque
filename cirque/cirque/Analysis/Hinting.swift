//
//  Hinting.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-31.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation

enum HintType {
	case radialDeviation(offset: Double, angle: Double)
}

extension TrailAnalyser {
	var bestHint: HintType {
		get {
			let data = radialDeviation()
			return .radialDeviation(offset: data.peak, angle: data.angle)
		}
	}
}
