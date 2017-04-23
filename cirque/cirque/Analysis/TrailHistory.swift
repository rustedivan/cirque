//
//  TrailHistory.swift
//  cirque
//
//  Created by Ivan Milles on 18/01/15.
//  Copyright (c) 2015 Rusted. All rights reserved.
//

import Foundation

struct TrendAnalysis : CustomDebugStringConvertible {
	let score: Double
	let fitness: Double
	let radius: Double
	let clockwise: Bool
	let contraction: Double
	let capSeparation: Double
	let radialDeviation: (angle: Double, direction: Double)
	
	var debugDescription : String {
		var out = ""
		out += "\n\tScore:       \(score > 0.0 ? "improving" : "worsening")"
		out += "\n\tDirection:   \(clockwise ? "mostly clockwise" : "mostly counter-clockwise")"
		out += "\n\tFitness:     \(fitness > 0.0 ? "improving" : "worsening")"
		out += "\n\tRadius:      \(radius > 0.0 ? "growing" : "shrinking")"
		out += "\n\tEnd angle:   \(contraction < 0.0 ? "stabilizing" : "worsening")"
		out += "\n\tSeparation:  \(capSeparation > 0.0 ? "widening" : "closing")"
		
		let direction = (radialDeviation.direction > 0.0 ? "outward" : "inward")
		let angle = radialDeviation.angle * 180 / .pi
		out += "\n\tHumps:       \(direction) at \(angle)º"
		
		return out
	}
}

class History : NSObject, NSCoding {
	static let Depth = 1000
	var scoreHistory: FixedTimeSeries
	var fitnessHistory: FixedTimeSeries
	var radiusHistory: FixedTimeSeries
	var clockwiseHistory: FixedTimeSeries
	var contractionHistory: FixedTimeSeries
	var capSeparationHistory: FixedTimeSeries
	var deviationAngleHistory: FixedTimeSeries
	var deviationMagnitudeHistory: FixedTimeSeries
	
	override init() {
		scoreHistory = FixedTimeSeries(depth: History.Depth)
		fitnessHistory = FixedTimeSeries(depth: History.Depth)
		radiusHistory = FixedTimeSeries(depth: History.Depth)
		clockwiseHistory = FixedTimeSeries(depth: History.Depth)
		contractionHistory = FixedTimeSeries(depth: History.Depth)
		capSeparationHistory = FixedTimeSeries(depth: History.Depth)
		deviationAngleHistory = FixedTimeSeries(depth: History.Depth)
		deviationMagnitudeHistory = FixedTimeSeries(depth: History.Depth)
		super.init()
	}
	
	func pushAnalysis(_ analysis: TrailAnalysis) {
		scoreHistory.add(analysis.circularityScore)
		fitnessHistory.add(analysis.radialFitness)
		radiusHistory.add(analysis.circleFit.radius)
		clockwiseHistory.add(analysis.isClockwise ? 1.0 : -1.0)
		contractionHistory.add(analysis.radialContraction)
		capSeparationHistory.add(analysis.endCapsSeparation)
		deviationAngleHistory.add(analysis.radialDeviation.angle)
		deviationMagnitudeHistory.add(analysis.radialDeviation.peak)
	}
	
	required init?(coder aDecoder: NSCoder) {
		let empty = FixedTimeSeries(depth: History.Depth)
		func decodeSeries(_ key: String) -> FixedTimeSeries {
			let stored = aDecoder.decodeObject(forKey: key) as? FixedTimeSeries.Coding
			return stored?.decoded as? FixedTimeSeries ?? empty
		}
		scoreHistory = decodeSeries("scoreHistory")
		fitnessHistory = decodeSeries("fitnessHistory")
		radiusHistory = decodeSeries("radiusHistory")
		clockwiseHistory = decodeSeries("clockwiseHistory")
		contractionHistory = decodeSeries("contractionHistory")
		capSeparationHistory = decodeSeries("capSeparationHistory")
		deviationAngleHistory = decodeSeries("deviationAngleHistory")
		deviationMagnitudeHistory = decodeSeries("deviationMagnitudeHistory")
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(scoreHistory.encoded, forKey: "scoreHistory")
		aCoder.encode(fitnessHistory.encoded, forKey: "fitnessHistory")
		aCoder.encode(radiusHistory.encoded, forKey: "radiusHistory")
		aCoder.encode(clockwiseHistory.encoded, forKey: "clockwiseHistory")
		aCoder.encode(contractionHistory.encoded, forKey: "contractionHistory")
		aCoder.encode(capSeparationHistory.encoded, forKey: "capSeparationHistory")
		aCoder.encode(deviationAngleHistory.encoded, forKey: "deviationAngleHistory")
		aCoder.encode(deviationMagnitudeHistory.encoded, forKey: "deviationMagnitudeHistory")
	}
}

class TrailHistory {
	var saveTimestamp: Date
	var history: History
	var filename: String?
	class var historyDir: String {
		get {
			let appSupportDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0] 
			let bundleId = Bundle.main.bundleIdentifier
			return appSupportDir + "/" + bundleId! + "/"
		}
	}
	
	init() {
		history = History()
		saveTimestamp = Date()
	}

	convenience init(filename: String) {
		self.init()
		
		self.filename = filename
		
		let loadData = try? Data(contentsOf: URL(fileURLWithPath: TrailHistory.historyDir + filename))
		if let data = loadData {
			let loader = NSKeyedUnarchiver(forReadingWith: data)
			saveTimestamp = (loader.decodeObject(forKey: "timestamp") as? Date) ?? Date()
			history = (loader.decodeObject(forKey: "history") as? History) ?? History()
		}
	}
	
	func addAnalysis(_ trail: TrailAnalysis) {
		history.pushAnalysis(trail)
	}
	
	func save() {
		if let savefile = filename {
			// Create /Application Support if needed:
			let directory = TrailHistory.historyDir
			let manager = FileManager.default
			if !manager.fileExists(atPath: directory) {
				do {
					try manager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
				} catch let error as NSError {
					debugPrint(error)
				}
			}
			
			let saveData = NSMutableData()
			let saver = NSKeyedArchiver(forWritingWith: saveData)
			saver.encode(Date(), forKey: "timestamp")
			saver.encode(history, forKey: "history")
			saver.finishEncoding()
			saveData.write(toFile: directory + savefile, atomically: true)
			
			let attribs = (try! FileManager.default.attributesOfItem(atPath: directory + savefile)) as NSDictionary
			print("History file has grown to \(attribs.fileSize() / 1024)kB.")
		}
	}
}

extension TrailHistory {
	var trendAnalysis: TrendAnalysis {
		let deviationTrend = recentDeviation(angleHistory: history.deviationAngleHistory, magnitudeHistory: history.deviationMagnitudeHistory)
		return TrendAnalysis(score: linearTrend(history.scoreHistory.timeSeries),
		                     fitness: linearTrend(history.fitnessHistory.timeSeries),
		                     radius: linearTrend(history.radiusHistory.timeSeries),
		                     clockwise: history.clockwiseHistory.average > 0.0,			// Most common value
												 contraction: abs(linearTrend(history.contractionHistory.timeSeries)),		// Magnitude of slope
		                     capSeparation: linearTrend(history.capSeparationHistory.timeSeries),
		                     radialDeviation: deviationTrend)
	}
	
	func recentDeviation(angleHistory: FixedTimeSeries, magnitudeHistory: FixedTimeSeries) -> (Double, Double) {
		let recentHistoryLength = 100
		let recentDeviationAngleHistory = angleHistory.timeSeries.suffix(recentHistoryLength)
		let recentDeviationMagnitudeHistory = magnitudeHistory.timeSeries.suffix(recentHistoryLength)
		let errorAngle = Double(recentDeviationAngleHistory.reduce(0.0, +) / Float(recentDeviationAngleHistory.count))
		let errorDirection = recentDeviationMagnitudeHistory.reduce(0.0, +) > 0.0 ? 1.0 : -1.0
		return (errorAngle, errorDirection)
	}
	
	func dumpTrends() {
		print(trendAnalysis)
	}
}
