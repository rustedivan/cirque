import CoreGraphics

typealias Polar = (a: Double, r: Double)

let modelRadius = 100.0
let errorTreshold = 4.0
let imperfectPoints = [Polar(a:  0.0, r: 102.0),	// In range
											 Polar(a:  1.0, r: 108.0),	// Positive overshoot
											 Polar(a:  2.0, r: 110.0),	// Positive overshoot
											 Polar(a:  3.0, r:  90.0),	// Negative overshoot
											 Polar(a:  4.0, r: 102.0)]		// In range

struct ErrorArea {
//	static func insertCrossoverPoints(points: [Polar], radius: Double, treshold: Double) -> [Polar] {
//		guard points.count > 1 else { return points }
//		
//		enum Classification { case Inside; case OnPath; case Outside }
//		
//		// TODO: try currying this
//		func classifyPoint(p: Polar, radius: Double, treshold: Double) -> Classification {
//			switch p.r - radius {
//			case (let d) where d > treshold: return .Outside
//			case (let d) where d < -treshold: return .Inside
//			default: return .OnPath
//			}
//		}
//		
//		var outPoints = [Polar]()
//		var prevPoint = points.first!
//		var prevClass = classifyPoint(points.first!, radius: radius, treshold: treshold)
//		for p in points[1..<points.endIndex] {
//			let currClass = classifyPoint(p, radius: radius, treshold: treshold)
//			if currClass != prevClass {
//				let k = (p.r - prevPoint.r) / (p.a - prevPoint.a)	// Slope
//				let m = prevPoint.r																// (Local) intercept
//				let y = radius																		// Zero line
//				let intersection = Polar(a: prevPoint.a + ((y - m) / k), r: radius)
//				
//				outPoints.append(intersection)
//			}
//			outPoints.append(p)
//			prevClass = currClass
//			prevPoint = p
//		}
//
//		return outPoints
//	}
	
	static func generateErrorArea(points: [Polar], radius: Double, treshold: Double) -> [Polar] {
		var outPoints: [Polar] = []
		for (i, p) in points.enumerate() {
			if fabs(p.r - radius) > treshold {
				let o = p
				let oNext = (i < points.endIndex) ? points[i + 1] : o
				let oPrev = (i > points.startIndex) ? points[i - 1] : o
				let r = Polar(a: o.a, r: radius)
				let rNext = Polar(a: oNext.a, r: radius)
				let rPrev = Polar(a: oPrev.a, r: radius)
				
				let prevPoint = (oPrev.r < rPrev.r) ? oPrev : rPrev
				let nextPoint = (oNext.r > rNext.r) ? oNext : rNext
				
				outPoints.appendContentsOf([o, r, prevPoint])	// Backward triangle
				outPoints.appendContentsOf([o, r, nextPoint])	// Forward triangle
			}
		}
		return outPoints
	}
}

let withCrossoverPoints = ErrorArea.generateErrorArea(imperfectPoints,
	                                                          radius: modelRadius,
	                                                          treshold: errorTreshold)

