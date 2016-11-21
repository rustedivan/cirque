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

struct CirqueUniforms {
	var modelViewProjection: matrix_float4x4
	var progress: Double
	
	init() {
		modelViewProjection = matrix_identity_float4x4
		progress = 0.0
	}
}

struct CirqueVertex {
	let position: vector_float4
}

protocol VertexSource {
	func toVertices() -> [CirqueVertex]
}

protocol Renderer {
	var uniforms: CirqueUniforms { get set }
	var renderTargetSize: CGSize { get set }
	func render(_ vertices: VertexSource)
}
