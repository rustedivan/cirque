//
//  TrailModel.swift
//  cirque
//
//  Created by Ivan Milles on 07/12/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import Darwin

struct Trail {
	static let segmentFilterDistance = 2.0
	
	fileprivate var points = PointArray()
	var angles: [Double] {
		return anglesBetweenPoints()
	}
	var distances: [Double] {
		return distancesBetweenPoints()
	}
	
	init() {
	}
	
	init(withPoints initialPoints: PointArray) {
		points = initialPoints
	}
	
	mutating func addPoint(_ p: Point) {
		guard points.last == nil || points.last! != p else { return }
		points.append(p)
	}
	
	fileprivate func anglesBetweenPoints() -> [Double] {
		guard points.count > 1 else { return [] }
		
		func angleBetween(_ p1: Point, _ p2: Point) -> Double {
			return atan2(p2.y - p1.y, p2.x - p1.x)
		}
		
		let segmentAngles = points.indices.map { i -> Double in
			if i == 0 {
				return angleBetween(points[0], points[1])
			} else if i == points.count - 1 {
				return angleBetween(points[i - 1], points[i])
			} else {
				return angleBetween(points[i - 1], points[i + 1])
			}
		}
		
		return segmentAngles
	}
	
	fileprivate func distancesBetweenPoints() -> [Double] {
		guard points.count > 1 else { return [] }
		
		func distanceBetween(_ p1: Point, _ p2: Point) -> Double {
			let dP = Vector(dx: p1.x - p2.x, dy: p1.y - p2.y)
			return sqrt(dP.dx * dP.dx + dP.dy * dP.dy)
		}
		
		let segmentLengths = points.indices.map { i -> Double in
			if i == 0 {
				return distanceBetween(points[0], points[1])
			} else {
				return distanceBetween(points[i - 1], points[i])
			}
		}
		
		return segmentLengths
	}
	
	func distanceFromEnd(_ point: Point) -> Double {
		guard let last = points.last else { return 0.0 }
		let p = Vector(dx: point.x - last.x,
		               dy: point.y - last.y)
		return sqrt(p.dx * p.dx + p.dy * p.dy)
	}
}

// Make the Trail into a proxy for the underlying PointArray
extension Trail : BidirectionalCollection {
	var startIndex: PointArray.Index {
		get { return points.startIndex }
	}
	var endIndex: PointArray.Index {
		get { return points.endIndex }
	}
	subscript(position: PointArray.Index) -> PointArray.Iterator.Element {
		get { return points[position] }
	}
	func index(after i: Int) -> Int {
		return points.index(after: i)
	}
	func index(before i: Int) -> Int {
		return points.index(before: i)
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

