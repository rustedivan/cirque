//
//  TrailHistory.swift
//  cirque
//
//  Created by Ivan Milles on 18/01/15.
//  Copyright (c) 2015 Rusted. All rights reserved.
//

import Foundation

class TrailHistory {
	var entries: [TrailAnalyser] = []
	var filename: String?
	class var historyDir: String {
		get {
			let appSupportDir = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0] 
			let bundleId = NSBundle.mainBundle().bundleIdentifier
			return appSupportDir + "/" + bundleId! + "/"
		}
	}
	
	init() {
	}

	convenience init(filename: String) {
		self.init()
		
		self.filename = filename
		
		let loadData = NSData(contentsOfFile: TrailHistory.historyDir + filename)
		if let data = loadData {
			let loader = NSKeyedUnarchiver(forReadingWithData: data)
			entries = loader.decodeObjectForKey("trails") as! [TrailAnalyser]
		}
	}
	
	func addAnalysis(trail: TrailAnalyser) {
		entries.append(trail)
	}
	
	func save() {
		if let savefile = filename {
			// Create /Application Support if needed:
			let directory = TrailHistory.historyDir
			let manager = NSFileManager.defaultManager()
			if !manager.fileExistsAtPath(directory) {
				do {
					try manager.createDirectoryAtPath(directory, withIntermediateDirectories: true, attributes: nil)
				} catch let error as NSError {
					debugPrint(error)
				}
			}
			
			let saveData = NSMutableData()
			let saver = NSKeyedArchiver(forWritingWithMutableData: saveData)
			saver.encodeObject(entries, forKey: "trails")
			saver.finishEncoding()
			saveData.writeToFile(directory + savefile, atomically: true)
			
			let attribs = (try! NSFileManager.defaultManager().attributesOfItemAtPath(directory + savefile)) as NSDictionary
			print("History file has grown to \(attribs.fileSize() / 1024)kB.")
		}
	}
}

extension TrailHistory {
	
	func circularityScoreProgression() -> Double {
		var scores = [Double]()
		for analysis in entries {
			scores.append(analysis.circularityScore())
		}
		
		let indices = [Int](0..<scores.count)

		let n = Double(scores.count)
		let sumT = indices.reduce(0.0) {$0 + Double($1)}
		let sumS = scores.reduce(0.0, combine: +)

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
			scores.append(analysis.circularityScore())
		}
		
		print(scores)
	}
}