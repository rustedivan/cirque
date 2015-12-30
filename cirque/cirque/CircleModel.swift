/// Swift Migrator:
///
/// This file contains one or more places using either an index
/// or a range with ArraySlice. While in Swift 1.2 ArraySlice
/// indices were 0-based, in Swift 2.0 they changed to match the
/// the indices of the original array.
///
/// The Migrator wrapped the places it found in a call to the
/// following function, please review all call sites and fix
/// incides if necessary.
@available(*, deprecated=2.0, message="Swift 2.0 migration: Review possible 0-based index")
private func __reviewIndex__<T>(value: T) -> T {
	return value
}

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
public class Circle: NSObject {
	var segmentFilterDistance: CGFloat {get {return 3.0}}
	var segments = Trail()
	
	func begin() {
	}
	
	func addSegment(p: CGPoint) {
		segments.addPoint(p)
	}
	
	func end() {
	}
	
	func polarizePoints(points: PointArray, around c: CGPoint) -> PolarArray {
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
	
	func distanceFromEnd(point: CGPoint) -> CGFloat {
		let p = CGVector(dx: point.x - segments.points.last!.x, dy: point.y - segments.points.last!.y)
		return sqrt(p.dx * p.dx + p.dy * p.dy)
	}
}

extension Circle {
	struct ArrayChunker: SequenceType {
		typealias Element = Range<Int>
		let stride: Int
		let count: Int
		
		init(count: Int, chunkSize stride: Int) {
			self.count = count
			self.stride = stride
		}
		
		func generate() -> AnyGenerator<Range<Int>> {
			var i = 0
			return anyGenerator { () -> Element? in
				guard i < self.count else { return nil }
				
				let out = Range(i ..< min(i + self.stride, self.count))
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
}