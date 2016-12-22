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

struct CirqueVertex {
	let position: vector_float4
	let color: vector_float4
}

// TODO: push into the renderers
// Solve conflict by path-specific extensions
struct TrailUniforms {
}

struct ErrorAreaUniforms {
	let progress: Double
	let errorFlashIntensity: Double
}
struct BestFitUniforms {
	let progress: Double
	let quality: Double
}

enum RenderWorld {
	case idle
	case drawing(circle: Circle)
	case rejection(circle: Circle, showAt: Point)
	case analysis(circle: Circle, fit: BestFitCircle, errorArea: ErrorArea)
	case scoring(circle: Circle, showAt: Point, score: Double)
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
