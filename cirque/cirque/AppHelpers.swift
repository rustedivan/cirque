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

// Inspired by Ruyichi Saito (https://medium.com/@ryuichi/swift-struct-nscoding-107fc2d6ba5e)
protocol Encodable {
	var encoded : Decodable? { get }
}

protocol Decodable {
	var decoded : Encodable? { get }
}

extension Sequence where Iterator.Element: Encodable {
	var encoded: [Decodable] {
		return flatMap { $0.encoded }
	}
}
extension Sequence where Iterator.Element: Decodable {
	var decoded: [Encodable] {
		return flatMap { $0.decoded }
	}
}
