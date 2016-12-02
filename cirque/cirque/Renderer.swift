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

struct CirqueUniforms {
	var modelViewProjection: matrix_float4x4
//	var progress: Double
	
	init() {
		modelViewProjection = matrix_identity_float4x4
//		progress = 0.0
	}
}

// $ This can be imported into the shaders 
struct CirqueVertex {
	let position: vector_float4
}

enum RenderPass: Hashable {
	typealias Identifier = String
	case trail
	case error (progress: Double)
	
	var passIdentifier: Identifier {
		switch self {
		case .trail: return "Trail pass"
		case .error: return "Error area pass"
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
	func renderPass(vertices: VertexSource,
	                inRenderPass renderPass: RenderPass,
	                intoCommandEncoder commandEncoder: RenderPath.Encoder)
	mutating func renderTargetSizeDidChange(to size: CGSize)
}

protocol Renderer {
	func render(vertices: VertexSource,
	            inRenderPass: RenderPass,
	            intoCommandEncoder: RenderPath.Encoder)
}

func ortho2d(l: Float, r: Float, b: Float, t: Float, n: Float, f: Float) -> matrix_float4x4 {
	let width = 1.0 / (r - l)
	let height = 1.0 / (t - b)
	let depth = 1.0 / (f - n)
	
	var p = float4(0.0)
	var q = float4(0.0)
	var r = float4(0.0)
	var s = float4(0.0)
	
	p.x = 2.0 * width
	q.y = 2.0 * height
	r.z = depth
	s.z = -n * depth
	s.w = 1.0
	
	return matrix_float4x4(columns: (p, q, r, s))
}
