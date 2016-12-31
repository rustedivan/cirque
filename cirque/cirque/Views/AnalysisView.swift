//
//  AnalysisView.swift
//  cirque
//
//  Created by Ivan Milles on 31/12/16.
//  Copyright © 2016 Rusted. All rights reserved.
//

import UIKit

class AnalysisView: UIView {
	struct ViewModel {
		let displayStartTime: Date
		let center: Point
		let radius: Double
		let angle: Double
	}
	
	private static let displayDuration = 1.5
	private static let countupDuration = 0.5

	var hintPointLayer: CAShapeLayer
	var viewModel = ViewModel(displayStartTime: .distantPast,
	                          center: zeroPoint,
	                          radius: 0.0,
	                          angle: 0.0)

	override init(frame: CGRect) {
		self.hintPointLayer = CAShapeLayer()
		
		super.init(frame: frame)
		
		layer.addSublayer(self.hintPointLayer)
		self.hintPointLayer.frame = layer.frame
		self.hintPointLayer.strokeColor = UIColor.clear.cgColor
		self.hintPointLayer.backgroundColor = UIColor.clear.cgColor
		self.hintPointLayer.fillColor = UIColor.orange.cgColor
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.hintPointLayer = CAShapeLayer()
		
		super.init(coder: aDecoder)
		
		layer.addSublayer(self.hintPointLayer)
		self.hintPointLayer.frame = layer.frame
		self.hintPointLayer.strokeColor = RenderStyle.bestFitColor.cgColor
		self.hintPointLayer.backgroundColor = UIColor.clear.cgColor
	}
	
	deinit {
		hintPointLayer.removeFromSuperlayer()
	}
	
	override func draw(_ rect: CGRect) {
		if Date().timeIntervalSince(viewModel.displayStartTime) < AnalysisView.displayDuration {
			let trailPath = UIBezierPath()
			let angle = -viewModel.angle // Invert angle to match UIView's flipped Y
			let targetVec = CGVector(dx: cos(angle) * viewModel.radius,
			                         dy: sin(angle) * viewModel.radius)
			let target = CGPoint(x: CGFloat(viewModel.center.x) + targetVec.dx,
			                     y: CGFloat(viewModel.center.y) + targetVec.dy)
			trailPath.move(to: CGPoint(point: viewModel.center))
			trailPath.addLine(to: target)
			
			hintPointLayer.path = trailPath.cgPath
		}
	}
	
	func presentAnalysis(showAt: Point, radius: Double, angle: Double) {
		viewModel = ViewModel(displayStartTime: Date(),
		                      center: showAt,
		                      radius: radius,
		                      angle: angle)
	}
}
