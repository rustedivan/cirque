//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

struct Circle {
	let segmentFilterDistance = 2.0
	var segments = Trail()
	
	func begin() {
	}
	
	mutating func addSegment(_ p: Point) {
		segments.addPoint(p)
	}
	
	func end() {
	}
	
	func distanceFromEnd(_ point: Point) -> Double {
		guard let last = segments.points.last else { return 0.0 }
		let p = Vector(dx: point.x - last.x,
									 dy: point.y - last.y)
		return sqrt(p.dx * p.dx + p.dy * p.dy)
	}
}

extension Circle {
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
		for line in ArrayChunker(count: segments.points.count, chunkSize: 5)
		{
			let pointsOnLine = segments.points[line]
			for point in pointsOnLine {
				print(String(format:"(%.2f, %.2f) as TestPoint, ", point.x, point.y), terminator: "")
			}
			print("")
		}
		print("] as [TestPoint]\n\n\n")
	}
	
	func dumpAsCSV() {
		print("\n\n\n\n")
		for point in segments.points	{
			print(String(format:"%f;\t%f", point.x, point.y))
		}
		print("\n\n\n")
	}
}
