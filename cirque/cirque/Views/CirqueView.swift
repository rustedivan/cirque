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
	var renderPath: AppRenderPath!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func render(renderState: State) {
		renderPath.renderFrame { encoder in
			
			switch renderState {
			case .idle, .rejecting:
				break
			case .drawing(let data):
				let uniforms = data.uniforms
				renderPath.renderPass(vertices: data.trail,
				                      inRenderPass: .trail(uniforms),
				                      intoEncoder: encoder)
				
			case .analysing(let data):
				let uniforms = data.errorUniforms
				renderPath.renderPass(vertices: data.errorArea,
				                      inRenderPass: .error(uniforms),
				                      intoEncoder: encoder)
				
				let trailUniforms = TrailUniforms()
				renderPath.renderPass(vertices: data.trail,
				                      inRenderPass: .trail(trailUniforms),
				                      intoEncoder: encoder)
				
				let bestFitUniforms = data.bestFitUniforms
				renderPath.renderPass(vertices: data.bestCircle,
				                      inRenderPass: .bestFit(bestFitUniforms),
				                      intoEncoder: encoder)
			case .scoring(let data):
				let trailUniforms = TrailUniforms()
				renderPath.renderPass(vertices: data.trail,
				                      inRenderPass: .trail(trailUniforms),
				                      intoEncoder: encoder)
			case .hinting(let data):
				let trailUniforms = TrailUniforms()
				renderPath.renderPass(vertices: data.trail,
				                      inRenderPass: .trail(trailUniforms),
				                      intoEncoder: encoder)
				let bestFitUniforms = data.bestFitUniforms
				renderPath.renderPass(vertices: data.bestCircle,
				                      inRenderPass: .bestFit(bestFitUniforms),
				                      intoEncoder: encoder)
			}
		}
	}
	
	override func didMoveToWindow() {
		contentScaleFactor = 2.0
		layer.backgroundColor = UIColor.white.cgColor
	}
	
	override func layoutSublayers(of layer: CALayer) {
		guard layer.sublayers != nil else { return }
		
		layer.frame = layer.bounds
		for subLayer in layer.sublayers! {
			subLayer.frame = layer.frame
		}
		
		if renderPath == nil {
			renderPath = AppRenderPath(layer: renderingLayer)
		}
		
		renderPath.renderTargetSizeDidChange(to: layer.bounds.size)
	}
}

// MARK: Simulator
#if arch(i386) || arch(x86_64)

extension CirqueView {
	typealias LayerType = CALayer
	
	var renderingLayer : LayerType {
		return layer
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
}
	
#endif
