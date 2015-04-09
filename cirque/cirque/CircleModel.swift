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
	func dumpAsSwiftArray() {
		let l = 5
		let a = segments.points
		var o = Array<ArraySlice<CGPoint>>()
		var i = 0
		while i+l < a.count {
			let s = a[i..<i+l]
			o.append(s)
			i += l
		}
		o.append(a[i..<a.count])
		
		println("\n\n\n\nlet a = [");
		for i in 0 ..< o.count {
			print("\t")
			for j in 0 ..< o[i].count {
				let x = Float(o[i][j].x)
				let y = Float(o[i][j].y)
				print(String(format:"(%.2f, %.2f) as TestPoint, ", x, y))
			}
			println("")
		}
		println("] as [TestPoint]\n\n\n")
	}
}