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
	var renderPath: RenderPath!
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func render(renderState: RenderWorld) {
		renderPath.runPasses { (commandEncoder) in
			
			switch renderState {
			case .idle:
				break
			case .drawing(let circle):
				renderPath.renderPass(vertices: circle.segments,
				                      inRenderPass: .trail,
				                      intoCommandEncoder: commandEncoder)
			case .analysis(let circle, let fit, let errorArea):
				renderPath.renderPass(vertices: errorArea,
															inRenderPass: .error(progress: 1.0),
															intoCommandEncoder: commandEncoder)
				
				renderPath.renderPass(vertices: circle.segments,
				                      inRenderPass: .trail,
				                      intoCommandEncoder: commandEncoder)
				renderPath.renderPass(vertices: fit,
				                      inRenderPass: .bestFit,
				                      intoCommandEncoder: commandEncoder)
			default: break
			}
			
			
//			renderPath.renderPass(vertices: errorArea,
//														inRenderPass: .error(progress: 1.0),
//														intoCommandEncoder: commandEncoder)
//		
//			renderPath.renderPass(vertices: circle.segments,
//			                      inRenderPass: .trail,
//			                      intoCommandEncoder: commandEncoder)
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