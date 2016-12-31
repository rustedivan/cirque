//
//  Uniforms.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-25.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation
import simd
import CoreGraphics.CGGeometry

struct FrameConstants {
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

struct TrailUniforms {
}

struct ErrorAreaUniforms {
	let progress: Float
	let errorFlashIntensity: Float
}

struct BestFitUniforms {
	let progress: Float
	let quality: Float
}

// Retro-model all state data as uniforms too
extension DrawingData {
	var uniforms: TrailUniforms {
		get {
			return TrailUniforms()
		}
	}
}

extension AnalysingData {
	var bestFitUniforms: BestFitUniforms {
		get {
			return BestFitUniforms(progress: Float(bestFitProgress().p),
			                       quality: 1.0)
		}
	}
	
	var errorUniforms: ErrorAreaUniforms {
		get {
			return ErrorAreaUniforms(progress: Float(errorProgress().p),
			                         errorFlashIntensity: 1.0)
		}
	}
}

extension HintingData {
	var bestFitUniforms: BestFitUniforms {
		get {
			return BestFitUniforms(progress: 1.0,
			                       quality: 1.0)
		}
	}
}
