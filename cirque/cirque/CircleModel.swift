//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

@objc
public class Circle: NSObject {
	var segments = Trail()
	
	func addSegment(p: CGPoint) {
		segments.addPoint(p)
	}
}
