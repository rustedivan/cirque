//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry

typealias Point = (x: Double, y: Double)
typealias Vector = (dx: Double, dy: Double)
typealias PointArray = [Point]
typealias Polar = (r: Double, a: Double)
typealias PolarArray = [Polar]
typealias AngleBucket = (points: PolarArray, angle: Double)

let zeroPoint = Point(x: 0.0, y: 0.0)

@objc
open class Circle: NSObject {
	var segmentFilterDistance: Double {get {return 2.0}}
	var segments = Trail()
	
	func begin() {
	}
	
	func addSegment(_ p: Point) {
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

func polarize(_ points: PointArray, around c: Point) -> PolarArray {
	var polar: PolarArray = []
	
	for i in 0 ..< points.count {
		var p = points[i]
		p.x -= c.x
		p.y -= c.y
		
		let a = atan2(p.y, p.x)
		let r = sqrt(p.x * p.x + p.y * p.y)
		
		polar.append((r: r, a: a))
	}
	
	// Normalize angles
	for i in 0 ..< polar.count {
		if polar[i].a < 0.0 { polar[i].a += M_PI * 2.0 }
		if polar[i].a > 2.0 * M_PI { polar[i].a -= M_PI * 2.0 }
	}
	
	return polar
}

struct ErrorArea {
	typealias ErrorBar = (a: Double, r: Double, isCap: Bool)
	var errorBars: [ErrorBar]
	var fitRadius: Double
	var center: Point
}

struct BestFitCircle {
	var lineWidths: [(a: Double, w: Double)]
	var fitRadius: Double
	var center: Point
}

extension Circle {
	static func generateErrorArea(_ points: [Polar], around: Point, radius: Double, treshold: Double) -> ErrorArea {
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
	
	static func generateBestFitCircle(around: Point, radius: Double, startAngle: Double, progress: Double, taper: Taper) -> BestFitCircle {
		var bestFitCircle = BestFitCircle(lineWidths: [], fitRadius: radius, center: around)
		let fidelity = 1.0/360.0
		let direction = taper.clockwise ? -1.0 : 1.0
		let endAngle = startAngle + progress * 2.0 * M_PI * direction
		let step = 2.0 * M_PI * fidelity * direction
		
		let arcs = stride(from: startAngle, through: endAngle, by: step)
		let widths = taper.taperWidths(angles: arcs)
		
		bestFitCircle.lineWidths = zip(arcs, widths).map {
			(a: $0, w: $1)
		}
			
		return bestFitCircle
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
