//
//  AppHelpers.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-25.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation

typealias Progress = () -> (p: Double, done: Bool)
func progress(duration: Double) -> Progress {
	let timestamp = Date()	// Captured by the closure
	return {
		let p = min(Date().timeIntervalSince(timestamp) / duration, 1.0)
		let d = (p >= 1.0)
		return (p: p, done: d)
	}
}
