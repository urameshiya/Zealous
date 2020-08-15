//
//  LyricGroupings.swift
//  Zealous
//
//  Created by Chinh Vu on 7/19/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

typealias LyricSegment = Range<String.Index>

// Groups parts that have similar traits
class LyricGrouping: Hashable {
	var name: String
	var segments = [LyricSegment]()
	
	init(name: String) {
		self.name = name
	}
	
	init(name: String, copyFrom other: LyricGrouping) {
		self.name = name
		segments = other.segments
	}
	
	func add(segment: LyricSegment) {
		segments.append(segment)
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}
	
	static func == (lhs: LyricGrouping, rhs: LyricGrouping) -> Bool {
		lhs.name == rhs.name
	}
}
