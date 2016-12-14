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
	func toVertices() -> VertexSource.Buffer {
		// Inner and outer vertices for each segment
		let segments = zip(self.angles, self.distances)
		let stroke = zip(self.points, segments)

		var vertices: VertexSource.Buffer = []
		
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
	func toVertices() -> VertexSource.Buffer {
		var polarPoints: [Polar] = []
		for (i, bar) in errorBars.enumerated() {
			if bar.isCap { continue }
			
			// For every error bar, look back and ahead (if possible)
			let prevBar = (i - 1 > errorBars.startIndex) ? errorBars[i - 1] : bar
			let thisBar = errorBars[i]
			let nextBar = (i + 1 < errorBars.endIndex) ? errorBars[i + 1] : bar
			
			// For the three error bars,
			// set points at the root(R) and tip(P)
			// so we can build two triangles.
			// One backward and down, one forward and up.
			var prevP = Polar(a: prevBar.a, r: prevBar.r)
			var prevR = Polar(a: prevBar.a, r: fitRadius)
			
			var thisP = Polar(a: thisBar.a, r: thisBar.r)
			var thisR = Polar(a: thisBar.a, r: fitRadius)
			
			var nextP = Polar(a: nextBar.a, r: nextBar.r)
			var nextR = Polar(a: nextBar.a, r: fitRadius)
			
			// Avoid twisted rectangles by flipping
			// the bars so they all point "outward" -
			// R has the smallest radius and P has the largest
			
			if prevR.r > prevP.r { swap (&prevR, &prevP) }
			if thisR.r > thisP.r { swap (&thisR, &thisP) }
			if nextR.r > nextP.r { swap (&nextR, &nextP) }
		
			// Constructing the back(B) and forward(F)
			// triangles from the six-point lattice
			//
			//				pP  tP__nP
			//				|  /|  /|
			//				| /B|F/ |
			//				|/__|/  |
			//				pR  tR  nR
			
			polarPoints.append(contentsOf: [prevR, thisP, thisR])	// Backward triangle
			polarPoints.append(contentsOf: [thisP, nextP, thisR])	// Forward triangle
		}
	
		// Finally, convert the polar points to vertices
		var out: VertexSource.Buffer = []
		for p in polarPoints {
			let v = CirqueVertex(position: [	Float(cos(p.a) * p.r + center.x),
																				Float(sin(p.a) * p.r + center.y),
																				0.0,
																				1.0 ])
			out.append(v)
		}
		
		return out
	}
}

extension BestFitCircle : VertexSource {
	// TODO: rewrite to use a less general Trail instead
	// TODO: set the trail width on Trail and use normalized widths instead
	func toVertices() -> VertexSource.Buffer {
		var out: VertexSource.Buffer = []
		
		for segment in lineWidths {
			let angle = segment.0
			let width = segment.1
			
			let pIn =  CGPoint(x: cos(angle) * (fitRadius - (width / 2.0)),
								 				 y: sin(angle) * (fitRadius - (width / 2.0)))
			let pOut = CGPoint(x: cos(angle) * (fitRadius + (width / 2.0)),
			                   y: sin(angle) * (fitRadius + (width / 2.0)))
			
			
			let vL = CirqueVertex(position: vector_float4(Float(pIn.x + center.x),
			                                              Float(pIn.y + center.y),
			                                              0.0, 1.0))
			let vR = CirqueVertex(position: vector_float4(Float(pOut.x + center.x),
			                                              Float(pOut.y + center.y),
			                                              0.0, 1.0))
			
			out.append(vL)
			out.append(vR)
		}
		return out
	}
}
