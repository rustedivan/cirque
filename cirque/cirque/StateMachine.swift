//
//  CirqueWorld.swift
//  cirque
//
//  Created by Ivan Milles on 2016-12-23.
//  Copyright © 2016 Rusted. All rights reserved.
//

import Foundation

struct DrawingData {
	let trail: Trail
}

struct AnalysingData {
	let trail: Trail
	let fit: BestFitCircle
	let errorArea: ErrorArea
	let bestFitProgress = progress(duration: 2.0)
	let errorProgress = progress(duration: 2.5)	
}

struct ScoringData {
	let trail: Trail
	let showAt: Point
	let score: Double
	let countupProgress = progress(duration: 1.0)
}

struct HintingData {
	let trail: Trail
	let fit: BestFitCircle
	let hint: HintType
}

struct RejectingData {
	let trail: Trail
	let showAt: Point
	let rejectionProgress = progress(duration: 0.5)
}

enum State : Equatable {
	case idle
	case drawing(DrawingData)
	case analysing(AnalysingData)
	case scoring(ScoringData)
	case hinting(HintingData)
	case rejecting(RejectingData)
	
	var name: String {
		switch self {
		case .idle: return "Idle"
		case .drawing: return "Drawing"
		case .analysing: return "Analysing"
		case .scoring: return "Scoring"
		case .hinting: return "Hinting"
		case .rejecting: return "Rejecting"
		}
	}
	
	static func == (lhs: State, rhs: State) -> Bool {
		return lhs.name == rhs.name
	}
}

struct StateMachine {
	let logDebug = true
	var onStateChange: ((State, State) -> ())?
	var currentState: State {
		willSet {
			guard currentState != newValue else { return }
			if logDebug {
				print("State: \(currentState.name) -> \(newValue.name)")
			}
			
			onStateChange?(currentState, newValue)
		}
	}
	init(startState: State) {
		currentState = startState
	}
}
