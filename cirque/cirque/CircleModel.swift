//
//  CircleModel.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import Foundation
import CoreGraphics.CGGeometry
import simd

typealias Point = CGPoint
typealias PointArray = Array<Point>
typealias Polar = (r: CGFloat, a: CGFloat)
typealias PolarArray = Array<Polar>
typealias AngleBucket = (points: PolarArray, angle: CGFloat)

@objc
public class Circle: NSObject {
	var segmentFilterDistance: CGFloat {get {return 2.0}}
	var segments = Trail()
	
	func begin() {
	}
	
	func addSegment(p: CGPoint) {
		segments.addPoint(p)
	}
	
	func end() {
	}
	
	func distanceFromEnd(point: CGPoint) -> CGFloat {
		let p = CGVector(dx: point.x - segments.points.last!.x, dy: point.y - segments.points.last!.y)
		return sqrt(p.dx * p.dx + p.dy * p.dy)
	}
}

func polarize(points: PointArray, around c: CGPoint) -> PolarArray {
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

struct ErrorArea: VertexSource {
	var polarPoints: [Polar]
	var center: CGPoint
	
	func toVertices() -> [CirqueVertex] {
		var out = [CirqueVertex]()
		for p in polarPoints {
			let x = Float(cos(p.a) * p.r)
			let y = Float(sin(p.a) * p.r)
			out.append(CirqueVertex(position: vector_float4(x, y, 0.0, 1.0)))
		}
		return out
	}
}

extension Circle {
	func generateErrorArea(points: [Polar], around: CGPoint, radius: CGFloat, treshold: CGFloat) -> ErrorArea {
		var errorArea = ErrorArea(polarPoints: [], center: around)
		for (i, p) in points.enumerate() {
			if fabs(p.r - radius) > treshold {
				let o = p
				let oNext = (i < points.endIndex) ? points[i + 1] : o
				let oPrev = (i > points.startIndex) ? points[i - 1] : o
				let r = Polar(a: o.a, r: radius)
				let rNext = Polar(a: oNext.a, r: radius)
				let rPrev = Polar(a: oPrev.a, r: radius)
				
				let prevPoint = (oPrev.r < rPrev.r) ? oPrev : rPrev
				let nextPoint = (oNext.r > rNext.r) ? oNext : rNext
				
				errorArea.polarPoints.appendContentsOf([o, r, prevPoint])	// Backward triangle
				errorArea.polarPoints.appendContentsOf([o, r, nextPoint])	// Forward triangle
			}
		}
		
		return errorArea
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
			return AnyGenerator { () -> Element? in
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