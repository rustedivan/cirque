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

extension Trail {
	struct ArrayChunker: Sequence {
		typealias Element = CountableRange<Int>
		let stride: Int
		let count: Int
		
		init(count: Int, chunkSize stride: Int) {
			self.count = count
			self.stride = stride
		}
		
		func makeIterator() -> AnyIterator<CountableRange<Int>> {
			var i = 0
			return AnyIterator { () -> Element? in
				guard i < self.count else { return nil }
				let out = i ..< Swift.min(i + self.stride, self.count)
				i += self.stride
				return out
			}
		}
	}
	
	func dumpAsSwiftArray() {
		print("\n\n\n\nlet a = [")
		for line in ArrayChunker(count: points.count, chunkSize: 5)
		{
			let pointsOnLine = points[line]
			for point in pointsOnLine {
				print(String(format:"(%.2f, %.2f) as TestPoint, ", point.x, point.y), terminator: "")
			}
			print("")
		}
		print("] as [TestPoint]\n\n\n")
	}
	
	func dumpAsCSV() {
		print("\n\n\n\n")
		for point in points	{
			print(String(format:"%f;\t%f", point.x, point.y))
		}
		print("\n\n\n")
	}
}
