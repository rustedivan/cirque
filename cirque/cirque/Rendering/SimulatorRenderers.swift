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

// MARK: Shape renderer
protocol ShapeRenderer : Renderer {
	var shapeLayer: CAShapeLayer { get }
}

// MARK: Specific shape renderers
class SimulatorCircleRenderer: ShapeRenderer {
	var shapeLayer: CAShapeLayer
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.frame = layer.frame
		self.shapeLayer.strokeColor = UIColor.clear.cgColor
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = UIColor.blue.cgColor
	}
	
	deinit {
		shapeLayer.removeFromSuperlayer()
	}
	
	func render(vertices: VertexSource,
	            inRenderPass renderPass: RenderPass,
	            intoCommandEncoder: RenderPath.Encoder) {
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
	
class SimulatorBestFitRenderer: ShapeRenderer {
	var shapeLayer: CAShapeLayer
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.frame = layer.frame
		self.shapeLayer.strokeColor = UIColor.clear.cgColor
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = UIColor.green.cgColor
	}
	
	deinit {
		shapeLayer.removeFromSuperlayer()
	}
	
	func render(vertices: VertexSource,
							inRenderPass renderPass: RenderPass,
							intoCommandEncoder: RenderPath.Encoder) {
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

class SimulatorErrorRenderer: ShapeRenderer {
	var shapeLayer: CAShapeLayer
	
	init(layer: CALayer) {
		self.shapeLayer = CAShapeLayer()
		layer.addSublayer(self.shapeLayer)
		self.shapeLayer.frame = layer.frame
		self.shapeLayer.strokeColor = UIColor.clear.cgColor
		self.shapeLayer.lineWidth = 1.0
		self.shapeLayer.backgroundColor = UIColor.clear.cgColor
		self.shapeLayer.fillColor = UIColor.red.cgColor
	}
	
	deinit {
		shapeLayer.removeFromSuperlayer()
	}
	
	func render(vertices: VertexSource,
	            inRenderPass renderPass: RenderPass,
	            intoCommandEncoder commandEncoder: RenderPath.Encoder) {
		let vertexArray = vertices.toVertices()
		guard vertexArray.count >= 3 else {
			shapeLayer.path = nil
			return
		}
		
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
