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
}

class TrailHistory {
	var entries: [TrailAnalysis] = []
	var filename: String?
	class var historyDir: String {
		get {
			let appSupportDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0] 
			let bundleId = Bundle.main.bundleIdentifier
			return appSupportDir + "/" + bundleId! + "/"
		}
	}
	
	init() {
	}

	convenience init(filename: String, slots: (immediate: Int, trend: Int, characteristic: Int)) {
		self.init()
		
		self.filename = filename
		
		let loadData = try? Data(contentsOf: URL(fileURLWithPath: TrailHistory.historyDir + filename))
		if let data = loadData {
			let loader = NSKeyedUnarchiver(forReadingWith: data)
			entries = loader.decodeObject(forKey: "trails") as! [TrailAnalysis]
		}
	}
	
	func addAnalysis(_ trail: TrailAnalysis) {
		entries.append(trail)
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
			saver.encode(entries, forKey: "trails")
			saver.finishEncoding()
			saveData.write(toFile: directory + savefile, atomically: true)
			
			let attribs = (try! FileManager.default.attributesOfItem(atPath: directory + savefile)) as NSDictionary
			print("History file has grown to \(attribs.fileSize() / 1024)kB.")
		}
	}
}

extension TrailHistory {
	var trendAnalysis: TrendAnalysis {
		return TrendAnalysis(score: circularityScoreProgression(),
		                     fitness: 0.0, radius: 0.0, clockwise: false, contraction: 0.0, capSeparation: 0.0)
	}
	
	func circularityScoreProgression() -> Double {
		var scores = [Double]()
		for analysis in entries {
			scores.append(analysis.circularityScore)
		}
		
		let indices = [Int](0..<scores.count)

		let n = Double(scores.count)
		let sumT = indices.reduce(0.0) {$0 + Double($1)}
		let sumS = scores.reduce(0.0, +)

		var sumST = 0.0
		for i in 0..<scores.count {
			sumST += Double(indices[i]) * scores[i]
		}
		
		let sumTT = indices.reduce(0.0) {$0 + Double($1 * $1)}
		let regression = (sumST - (sumS * sumT)/n) / (sumTT - sumT*sumT/n)
		
		return regression
	}
	
	func dumpScoreHistory() {
		var scores = [Double]()
		for analysis in entries {
			scores.append(analysis.circularityScore)
		}
		
		print(scores)
	}
}
