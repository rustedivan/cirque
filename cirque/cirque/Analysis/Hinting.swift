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
	func bestHint(analysis: TrendAnalysis) -> HintType {
		return .radialDeviation(offset: analysis.radialDeviation.direction,
		                        angle: analysis.radialDeviation.angle)
	}
}
