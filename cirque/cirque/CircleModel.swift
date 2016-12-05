//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

typealias Point = CGPoint
typealias PointArray = Array<Point>
typealias Polar = (r: CGFloat, a: CGFloat)
typealias PolarArray = Array<Polar>
typealias AngleBucket = (points: PolarArray, angle: CGFloat)

@objc
open class Circle: NSObject {
	var segmentFilterDistance: CGFloat {get {return 2.0}}
	var segments = Trail()
	
	func begin() {
	}
	
	func addSegment(_ p: CGPoint) {
		segments.addPoint(p)
	}
	
	func end() {
	}
	
	func distanceFromEnd(_ point: CGPoint) -> CGFloat {
		let p = CGVector(dx: point.x - segments.points.last!.x, dy: point.y - segments.points.last!.y)
		return sqrt(p.dx * p.dx + p.dy * p.dy)
	}
}

func polarize(_ points: PointArray, around c: CGPoint) -> PolarArray {
	var polar: PolarArray = []
	
	for i in 0 ..< points.count {
		var p = points[i]
		p.x -= c.x
		p.y -= c.y
		
		let a = CGFloat(atan2f(Float(p.y), Float(p.x)))
		let r = sqrt(p.x * p.x + p.y * p.y)
		
		polar.append((r: r, a: a))
	}
	
	// Normalize angles
	for i in 0 ..< polar.count {
		if polar[i].a < 0.0 {polar[i].a += CGFloat(M_PI * 2.0)}
		if polar[i].a > CGFloat(2.0 * M_PI) {polar[i].a -= CGFloat(M_PI * 2.0)}
	}
	
	return polar
}

struct ErrorArea {
	typealias ErrorBar = (a: CGFloat, r: CGFloat, isCap: Bool)
	var errorBars: [ErrorBar]
	var fitRadius: CGFloat
	var center: CGPoint
}

extension Circle {
	static func generateErrorArea(_ points: [Polar], around: CGPoint, radius: CGFloat, treshold: CGFloat) -> ErrorArea {
		var errorArea = ErrorArea(errorBars: [], fitRadius: radius, center: around)
		
		var insideErrorArea = false
		for (i, p) in points.enumerated() {
			if fabs(p.r - radius) > treshold {
				let prev = (i - 1 > points.startIndex) ? points[i - 1] : p
				
				// Cap the start of the error area
				if !insideErrorArea {
					errorArea.errorBars.append((a: prev.a, r: radius, isCap: true))
					insideErrorArea = true
				}
				
				errorArea.errorBars.append((a: p.a, r: p.r, isCap: false))
			} else if insideErrorArea {
				// Cap the end of the error area
				errorArea.errorBars.append((a: p.a, r: radius, isCap: true))
				insideErrorArea = false
			}
		}
		
		return errorArea
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
