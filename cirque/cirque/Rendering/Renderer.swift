//
//  Renderer.swift
//  cirque
//
//  Created by Ivan Milles on 2016-11-20.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation
import simd
import CoreGraphics.CGGeometry
import QuartzCore

struct CirqueConstants {
	var modelViewProjection: matrix_float4x4
	
	init(projectionSize: CGSize) {
		var mvpMatrix: matrix_float4x4
		mvpMatrix = ortho2d(l: 0.0, r: projectionSize.width,
		                    b: projectionSize.height, t: 0.0,
		                    n: 0.0, f: 1.0)
		
		// Translate into Metal's NDC space (2x2x1 unit cube)
		mvpMatrix.columns.3.x = -1.0
		mvpMatrix.columns.3.y = +1.0
		modelViewProjection = mvpMatrix
	}
}

struct CirqueUniforms {
	var progress: Float = 0.0
}

struct CirqueVertex {
	let position: vector_float4
	let color: vector_float4
}

enum RenderWorld {
	case idle
	case drawing(circle: Circle)
	case rejection(circle: Circle, showAt: Point)
	case analysis(circle: Circle, fit: BestFitCircle, errorArea: ErrorArea)
	case scoring(circle: Circle, showAt: Point, score: Double)
}

enum RenderPass: Hashable {
	typealias Identifier = String
	case trail
	case error (progress: Double)
	case bestFit
	
	var passIdentifier: Identifier {
		switch self {
		case .trail: return "Trail pass"
		case .error: return "Error area pass"
		case .bestFit: return "Best fit pass"
		}
	}
	
	var hashValue: Int {
		return passIdentifier.hashValue
	}
	
	public static func ==(lhs: RenderPass, rhs: RenderPass) -> Bool {
		return lhs.passIdentifier == rhs.passIdentifier
	}
}

protocol VertexSource {
	typealias Buffer = ContiguousArray<CirqueVertex>
	func toVertices() -> Buffer
}

protocol RenderPath {
#if arch(i386) || arch(x86_64)
	typealias Encoder = Void
#else
	typealias Encoder = MTLRenderCommandEncoder
#endif
	
	func runPasses(renderAllPasses : (RenderPath.Encoder) -> () )
	func renderPass(_ renderPass: RenderPass,
	                vertices: VertexSource,
	                intoCommandEncoder commandEncoder: RenderPath.Encoder)
	mutating func renderTargetSizeDidChange(to size: CGSize)
}

protocol Renderer {
	func render(vertices: VertexSource,
	            inRenderPass: RenderPass,
	            intoCommandEncoder: RenderPath.Encoder)
}

}
