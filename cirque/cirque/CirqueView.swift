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
	enum RenderPass {
		case trail
		case error (progress: Double)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func didMoveToWindow() {
		contentScaleFactor = 2.0
		layer.backgroundColor = UIColor.white.cgColor
	}
	
	func render(vertices: VertexSource, inRenderPass renderPass: RenderPass) {
		var renderer = setupRenderer(forRenderPass: renderPass)
		
		switch renderPass {
		case .error(let progress):
			renderer.uniforms.progress = progress
		}
		
		// Setup projection matrix
		var mvpMatrix = ortho2d(l: 0.0, r: Float(renderTargetSize.width),
		                        b: Float(renderTargetSize.height), t: 0.0,
		                        n: 0.0, f: 1.0)
		
		// Translate into Metal's NDC space (2x2x1 unit cube)
		mvpMatrix.columns.3.x = -1.0
		mvpMatrix.columns.3.y = +1.0
		
		// Setup common uniforms
		renderer.uniforms.modelViewProjection = mvpMatrix
		
		renderer.render(vertices)
	}
}

// MARK: Simulator
#if arch(i386) || arch(x86_64)

extension CirqueView {
	func setupRenderer(forRenderPass renderPass: Layer) {
		switch renderPass {
		case .trail:
			return SimulatorCircleRenderer(layer: layer)
		case .errorArea:
			return SimulatorErrorRenderer(layer: layer)
		}
	}
	
	override func layoutSublayers(of layer: CALayer) {
		guard layer.sublayers != nil else { return }
		
		for subLayer in layer.sublayers! {
			subLayer.frame = layer.frame
		}
	}
}
	
#else
// MARK: Metal
	
import Metal
	
extension CirqueView {
	typealias LayerType = CAMetalLayer
	
	var layerClass: AnyClass {
		return LayerType.self
	}
	
	var renderingLayer : LayerType {
		return layer as! LayerType
	}
	
	func setupRenderer(forRenderPass renderPass: RenderPass) -> Renderer {
		return MetalRenderer(layer: renderingLayer)
	}
	
	override func layoutSublayers(of layer: CALayer) {
		renderingLayer.frame = layer.bounds
		renderingLayer.drawableSize = CGSize(width: layer.bounds.width * contentScaleFactor, height: layer.bounds.height * contentScaleFactor)
		renderer.renderTargetSize = renderingLayer.drawableSize
	}
}
	
#endif
