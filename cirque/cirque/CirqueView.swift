//
//  CirqueView.swift
//  cirque
//
//  Created by Ivan Milles on 24/01/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit

// MARK: Base view

class CirqueView: UIView {
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

		public static func ==(lhs: CirqueView.RenderPass, rhs: CirqueView.RenderPass) -> Bool {
			return lhs.passIdentifier == rhs.passIdentifier
		}
	}
	
	var activeRenderers: [RenderPass : Renderer] = [:]
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setupRenderers(toLayer: renderingLayer)
	}
	
	override func didMoveToWindow() {
		contentScaleFactor = 2.0
		layer.backgroundColor = UIColor.white.cgColor
	}
	
	func render(vertices: VertexSource, inRenderPass renderPass: RenderPass) {
		guard var renderer = activeRenderers[renderPass] else {
			print("Ignoring unregistered render pass \(renderPass.passIdentifier)")
			return
		}
		
		var uniforms = CirqueUniforms()
		
		switch renderPass {
		case .error(let progress):
			uniforms.progress = progress
		default: break
		}
		
		// Setup projection matrix
		var mvpMatrix = ortho2d(l: 0.0, r: Float(renderer.renderTargetSize.width),
		                        b: Float(renderer.renderTargetSize.height), t: 0.0,
		                        n: 0.0, f: 1.0)
		
		// Translate into Metal's NDC space (2x2x1 unit cube)
		mvpMatrix.columns.3.x = -1.0
		mvpMatrix.columns.3.y = +1.0
		
		// Setup common uniforms
		uniforms.modelViewProjection = mvpMatrix
		
		renderer.render(vertices, withUniforms: uniforms)
	}
	
	override func layoutSublayers(of layer: CALayer) {
		guard layer.sublayers != nil else { return }
		
		layer.frame = layer.bounds
		for subLayer in layer.sublayers! {
			subLayer.frame = layer.frame
		}
		
		for var renderer in activeRenderers {
			renderer.value.renderTargetSize = layer.bounds.size
		}
	}
}

// MARK: Simulator
#if arch(i386) || arch(x86_64)

extension CirqueView {
	typealias LayerType = CALayer
	
	var renderingLayer : LayerType {
		return layer
	}
	
	func setupRenderers(toLayer targetLayer: LayerType) {
		activeRenderers = [.trail								 : SimulatorCircleRenderer(layer: targetLayer),
		                   .error(progress: 0.0) : SimulatorErrorRenderer(layer: targetLayer)]
	}
}
	
#else
// MARK: Metal
	
import Metal
	
extension CirqueView {
	typealias LayerType = CAMetalLayer
	
	override class var layerClass: Swift.AnyClass {
		return LayerType.self
	}
	
	var renderingLayer : LayerType {
		return layer as! LayerType
	}
	
	func setupRenderers(toLayer targetLayer: LayerType) {
		activeRenderers = [.trail : MetalRenderer(layer: renderingLayer)]
	}
}
	
#endif
