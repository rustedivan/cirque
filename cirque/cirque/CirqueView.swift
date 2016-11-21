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
	enum Layer {
		case trail
		case error (progress: Double)
	}
	
	var circleRenderer: Renderer!
	var errorRenderer: Renderer!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func didMoveToWindow() {
		contentScaleFactor = 2.0
		layer.backgroundColor = UIColor.white.cgColor
		setupRenderers()
	}
	
	func render(vertices: VertexSource, toLayer layer: Layer) {
		switch layer {
		case .trail:
			circleRenderer.render(vertices)
		case .error(let progress):
			errorRenderer.uniforms.progress = progress
			errorRenderer.render(vertices)
		}
	}
}

// MARK: Simulator
#if arch(i386) || arch(x86_64)

extension CirqueView {
	func setupRenderers() {
		errorRenderer =	SimulatorErrorRenderer(layer: layer)
		circleRenderer = SimulatorCircleRenderer(layer: layer)
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
	
	func setupRenderer() -> Renderer {
		return MetalRenderer(layer: renderingLayer)
	}
	
	override func layoutSublayers(of layer: CALayer) {
		renderingLayer.frame = layer.bounds
		renderingLayer.drawableSize = CGSize(width: layer.bounds.width * contentScaleFactor, height: layer.bounds.height * contentScaleFactor)
		renderer.renderTargetSize = renderingLayer.drawableSize
	}
}
	
#endif
