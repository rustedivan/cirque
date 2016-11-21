//
//  VertexConversion.swift
//  cirque
//
//  Created by Ivan Milles on 2016-11-20.
//  Copyright © 2016 Rusted. All rights reserved.
//

import CoreGraphics.CGGeometry
import simd

extension Trail : VertexSource {
	func toVertices() -> [CirqueVertex] {
		// Inner and outer vertices for each segment
		let segments = zip(self.angles, self.distances)
		let stroke = zip(self.points, segments)
		
		var vertices: [CirqueVertex] = []
		
		for segment in stroke {
			let pC = segment.0
			let angle = segment.1.0
			let length = segment.1.1
			let width = CGFloat(2.0) + log2(length)
			let span = CGVector(dx: sin(angle) * width / 2.0, dy: -cos(angle) * width / 2.0)
			
			let pL = CirqueVertex(position: vector_float4(Float(pC.x + span.dx), Float(pC.y + span.dy), 0.0, 1.0))
			let pR = CirqueVertex(position: vector_float4(Float(pC.x - span.dx), Float(pC.y - span.dy), 0.0, 1.0))
			
			vertices.append(pL)
			vertices.append(pR)
		}
		
		return vertices
	}
}

extension ErrorArea : VertexSource {
	func toVertices() -> [CirqueVertex] {
		var out = [CirqueVertex]()
		for p in polarPoints {
			let x = Float(cos(p.a) * p.r + center.x)
			let y = Float(sin(p.a) * p.r + center.y)
			out.append(CirqueVertex(position: vector_float4(x, y, 0.0, 1.0)))
		}
		return out
	}
}
