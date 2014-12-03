//
//  CircleController.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation

class CircleController: NSObject {
	var circle: Circle = Circle()
	
	func draw(view: CircleView) {
		view.render(circle);
	}
}
