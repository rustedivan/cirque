//
//  TrailHistory.swift
//  cirque
//
//  Created by Ivan Milles on 18/01/15.
//  Copyright (c) 2015 Rusted. All rights reserved.
//

import Foundation

struct TrendAnalysis {
	let score: Double
	let fitness: Double
	let radius: Double
	let clockwise: Bool
	let contraction: Double
	let capSeparation: Double
	let radialDeviation: (angle: Double, direction: Double)
}

class History {
	static let Depth = 1000
	var scoreHistory: FixedTimeSeries
	var fitnessHistory: FixedTimeSeries
	var radiusHistory: FixedTimeSeries
	var clockwiseHistory: FixedTimeSeries
	var contractionHistory: FixedTimeSeries
	var capSeparationHistory: FixedTimeSeries
	var deviationAngleHistory: FixedTimeSeries
	var deviationMagnitudeHistory: FixedTimeSeries
	
	init(_ slots: (immediate: Int, trend: Int, characteristic: Int)) {
		scoreHistory = FixedTimeSeries(depth: History.Depth)
		fitnessHistory = FixedTimeSeries(depth: History.Depth)
		radiusHistory = FixedTimeSeries(depth: History.Depth)
		clockwiseHistory = FixedTimeSeries(depth: History.Depth)
		contractionHistory = FixedTimeSeries(depth: History.Depth)
		capSeparationHistory = FixedTimeSeries(depth: History.Depth)
		deviationAngleHistory = FixedTimeSeries(depth: History.Depth)
		deviationMagnitudeHistory = FixedTimeSeries(depth: History.Depth)
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
}

class TrailHistory {
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
		history = History((immediate: 0, trend: 0, characteristic: 0))
	}

	convenience init(filename: String) {
		self.init()
		
		self.filename = filename
		
		let loadData = try? Data(contentsOf: URL(fileURLWithPath: TrailHistory.historyDir + filename))
		if let data = loadData {
			let loader = NSKeyedUnarchiver(forReadingWith: data)
			history = loader.decodeObject(forKey: "history") as! History
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
			saver.encode(history, forKey: "trails")
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
	
	func dumpScoreHistory() {
		let scores = [Double]()
//		for analysis in entries {
//			scores.append(analysis.circularityScore)
//		}
//		
		print(scores)
	}
}
