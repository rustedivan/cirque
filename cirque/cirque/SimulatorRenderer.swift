//
//  SimulatorRenderer.swift
//  cirque
//
//  Created by Ivan Milles on 2016-11-20.
//  Copyright © 2016 Rusted. All rights reserved.
//

// If building for simulator (Metal not available)

#if arch(i386) || arch(x86_64)

import UIKit
	
extension CGPoint {
	init(vertex: CirqueVertex) {
		self.init(x: CGFloat(vertex.position.x), y: CGFloat(vertex.position.y))
	}
}

struct SimulatorCircleRenderer: Renderer {
	let shapeLayer: CAShapeLayer
	var uniforms: CirqueUniforms
	
	var renderTargetSize: CGSize {
		get { return shapeLayer.bounds.size }
		set { shapeLayer.bounds.size = renderTargetSize }
	}
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.frame = layer.frame
		self.shapeLayer.strokeColor = UIColor.clear.cgColor
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = UIColor.blue.cgColor
		self.uniforms = CirqueUniforms()
	}
	
	func render(_ vertices: VertexSource) {
		let vertexArray = vertices.toVertices()
		let trailPath = UIBezierPath()
		
		guard vertexArray.count >= 3 else { return }
		let triangleFanStream = vertexArray[0 ..< vertexArray.endIndex - 2]
		for (i, p) in triangleFanStream.enumerated() {
			trailPath.move(to: CGPoint(vertex: p))
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i + 1]))
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i + 2]))
			trailPath.close()
		}
		
		shapeLayer.path = trailPath.cgPath
	}
}

struct SimulatorErrorRenderer: Renderer {
	let shapeLayer: CAShapeLayer
	var uniforms: CirqueUniforms
	
	var renderTargetSize: CGSize {
		get { return shapeLayer.bounds.size }
		set { shapeLayer.bounds.size = renderTargetSize }
	}
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.bounds = layer.bounds
		self.shapeLayer.strokeColor = UIColor.clear.cgColor
		self.shapeLayer.lineWidth = 1.0
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = UIColor.red.cgColor
		self.uniforms = CirqueUniforms()
	}
	
	func render(_ vertices: VertexSource) {
		let vertexArray = vertices.toVertices()
		guard vertexArray.count >= 3 else { return }
		
		let trailPath = UIBezierPath()
		
		var i = 0;
		repeat {
			trailPath.move(to:		CGPoint(vertex: vertexArray[i + 0]))
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i + 1]))
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i + 2]))
			trailPath.close()
			i = i + 3
		} while i + 3 < vertexArray.count
		
		shapeLayer.path = trailPath.cgPath
	}
}

#endif
