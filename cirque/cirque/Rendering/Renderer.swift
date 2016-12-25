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

struct CirqueVertex {
	let position: vector_float4
	let color: vector_float4
}

enum RenderPass {
	case trail(_: TrailUniforms)
	case error(_: ErrorAreaUniforms)
	case bestFit(_: BestFitUniforms)
}

protocol VertexSource {
	typealias Buffer = ContiguousArray<CirqueVertex>
	func toVertices() -> Buffer
}

// MARK: Render path

protocol RenderPath {
	associatedtype Encoder
	associatedtype TrailRenderer
	associatedtype ErrorAreaRenderer
	associatedtype BestFitRenderer
	
	var trailRenderer: TrailRenderer { get }
	var errorRenderer: ErrorAreaRenderer { get }
	var bestFitRenderer: BestFitRenderer { get }
	
	func renderFrame(allRenderPasses : (Encoder) -> () )
	func renderPass(vertices: VertexSource, inRenderPass: RenderPass, intoEncoder: Encoder)
	mutating func renderTargetSizeDidChange(to size: CGSize)
}

// MARK: Renderers

protocol Renderer {
	associatedtype Encoder
	associatedtype Uniforms
	
	func render(vertices: VertexSource,
	            withUniforms: Uniforms,
	            intoEncoder: Encoder)
}
