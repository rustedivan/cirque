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
	init(point: Point) {
		self.init(x: CGFloat(point.x), y: CGFloat(point.y))
	}
}

class CGTrailRenderer<Encoder>: Renderer {
	var shapeLayer: CAShapeLayer
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.frame = layer.frame
		self.shapeLayer.strokeColor = UIColor.clear.cgColor
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = RenderStyle.trailColor.cgColor
	}
	
	deinit {
		shapeLayer.removeFromSuperlayer()
	}
	
	func render(vertices: VertexSource,
	            withUniforms uniforms: TrailUniforms,
	            intoEncoder: Encoder) {
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
	
class CGBestFitRenderer<Encoder>: Renderer {
	var shapeLayer: CAShapeLayer
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.frame = layer.frame
		self.shapeLayer.strokeColor = UIColor.clear.cgColor
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = RenderStyle.bestFitColor.cgColor
	}
	
	deinit {
		shapeLayer.removeFromSuperlayer()
	}
	
	func render(vertices: VertexSource,
							withUniforms uniforms: BestFitUniforms,
							intoEncoder: Encoder) {
		let vertexArray = vertices.toVertices()
		let trailPath = UIBezierPath()
		
		let drawProgress = uniforms.progress
		let vertexCount = Int(Double(vertexArray.count) * drawProgress)
		
		guard vertexArray.count >= 3 else { return }
		let triangleStripStream = vertexArray[0 ..< vertexCount - 2]
		for (i, p) in triangleStripStream.enumerated() {
			trailPath.move(to: CGPoint(vertex: p))
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i + 1]))
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i + 2]))
			trailPath.close()
		}
		
		shapeLayer.path = trailPath.cgPath
	}
}

class CGErrorRenderer<Encoder>: Renderer {
	var shapeLayer: CAShapeLayer
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.frame = layer.frame
		self.shapeLayer.strokeColor = UIColor.clear.cgColor
		self.shapeLayer.lineWidth = 1.0
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = RenderStyle.errorColor.cgColor
	}
	
	deinit {
		shapeLayer.removeFromSuperlayer()
	}
	
	func render(vertices: VertexSource,
	            withUniforms uniforms: ErrorAreaUniforms,
	            intoEncoder encoder: Encoder) {
		let vertexArray = vertices.toVertices()
		guard vertexArray.count >= 3 else {
			shapeLayer.path = nil
			return
		}
		
		let errorProgress = uniforms.progress
		let vertexCount = Int(Double(vertexArray.count) * errorProgress)
		
		let trailPath = UIBezierPath()
		
		var i = 0;
		repeat {
			trailPath.move(to:		CGPoint(vertex: vertexArray[i + 0]))
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i + 1]))
			trailPath.addLine(to: CGPoint(vertex: vertexArray[i + 2]))
			trailPath.close()
			i = i + 3
		} while i + 3 < vertexCount
		
		shapeLayer.path = trailPath.cgPath
	}
}

#endif
