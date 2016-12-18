//
//  Style.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-18.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit
import simd

struct RenderStyle {
	static let backgroundColor = UIColor(colorLiteralRed: 0.112, green: 0.301, blue: 0.368, alpha: 1.0)
	static let trailColor = UIColor(colorLiteralRed: 0.95, green: 0.98, blue: 1.0, alpha: 0.9)
	static let errorColor = UIColor(colorLiteralRed: 1.0, green: 0.1, blue: 0.0, alpha: 0.7)
	static let bestFitColor = UIColor(colorLiteralRed: 0.0, green: 0.9, blue: 0.2, alpha: 1.0)
}

extension UIColor {
	var vec4: vector_float4 {
		get {
			var r: CGFloat = 0.0
			var g: CGFloat = 0.0
			var b: CGFloat = 0.0
			var a: CGFloat = 0.0
			self.getRed(&r, green: &g, blue: &b, alpha: &a)
			return vector_float4([Float(r), Float(g), Float(b), Float(a)])
		}
	}
}
