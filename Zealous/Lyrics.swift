//
//  Lyrics.swift
//  Zealous
//
//  Created by Chinh Vu on 6/24/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

class SegmentMarker<Index>: Comparable where Index: Comparable {
	static func == (lhs: SegmentMarker, rhs: SegmentMarker) -> Bool {
		return lhs.index == rhs.index
	}
	
	static func < (lhs: SegmentMarker, rhs: SegmentMarker) -> Bool {
		lhs.index < rhs.index
	}
	
	var index: Index
	var isValid = false
	
	init(index: Index, isValid: Bool = false) {
		self.index = index
	}
}

// Mechanism to mark segments of strings
class LyricSeparator {
	typealias Index = String.Index
	let lyric: String
		
	var segments: GapSegmentedRange<Index>
	private var validator: LyricSegmentValidating = TrimmingWhitespaceValidator()
			
	init(lyric: String) {
		self.lyric = lyric
		segments = .init(maxRange: lyric.startIndex..<lyric.endIndex)
		
		// split new liness
		let splits = lyric.split(whereSeparator: { $0.isNewline })
		for substr in splits {
			for validated in validator.validate(string: substr) {
				segments.mark(index: validated.lowerBound, enabled: true)
				segments.mark(index: validated.upperBound, enabled: false)
			}
		}
	}
	
	func cutSegment(at pos: Index) -> (old: Range<Index>, new:[Range<Index>])? {
		guard let (oldSegment, isEnabled) = segments.segment(containing: pos),
			oldSegment.lowerBound != pos,
			isEnabled else {
			return nil
		}
		let newSegments = [oldSegment.lowerBound..<pos, pos..<oldSegment.upperBound]
		
		var result = [Range<Index>]()
		
		for segment in newSegments {
			let substr = lyric[segment]
			let modifies = validator.validate(string: substr)
			for modify in modifies {
				segments.mark(index: modify.lowerBound, enabled: true)
				if modify.upperBound < oldSegment.upperBound {
					segments.mark(index: modify.upperBound, enabled: false)
				}
			}
			result.append(contentsOf: modifies)
		}
		return result.isEmpty ? nil : (oldSegment, result)
	}
}

class GapSegmentedRange<Index> where Index: Comparable {
	class Marker: Comparable {
		static func == (lhs: Marker, rhs: Marker) -> Bool {
			return lhs.index == rhs.index
		}
		
		static func < (lhs: Marker, rhs: Marker) -> Bool {
			lhs.index < rhs.index
		}
		
		var index: Index
		var isValid = false
		
		init(index: Index, isValid: Bool = false) {
			self.index = index
			self.isValid = isValid
		}
	}

	let segments: SegmentedRange<Marker>
	
	init(maxRange: Range<Index>) {
		segments = .init(Marker(index: maxRange.lowerBound)..<Marker(index: maxRange.upperBound))
	}
	
	func mark(index: Index, enabled: Bool) {
		segments.insertOrUpdate(marker: Marker(index: index, isValid: enabled))
	}
	
	func removeMarker(at index: Index) {
		_ = segments.remove(marker: Marker(index: index))
	}
	
	func segment(containing index: Index) -> (range: Range<Index>, enabled: Bool)? {
		guard let seg = segments.segment(containing: Marker(index: index)) else {
			return nil
		}
		return (seg.lowerBound.index..<seg.upperBound.index, seg.lowerBound.isValid)
	}
}

class SegmentedRange<Index> where Index: Comparable {
	var markers = SimpleBST<Index>()
	private let maxRange: Range<Index>
	
	init(_ range: Range<Index>) {
		assert(range.lowerBound <= range.upperBound)
		markers.insert(range.lowerBound)
		markers.insert(range.upperBound)
		maxRange = range
	}
	
	func insertMarker(marker: Index) -> Bool {
		return markers.insert(marker)
	}
	
	func insertOrUpdate(marker: Index) {
		_ = markers.insertOrUpdate(with: marker)
	}
	
	func remove(marker: Index) -> Index? {
		return markers.remove(marker)
	}
	
	func segment(containing index: Index) -> Range<Index>? {
		guard let next = markers.successor(of: index) else {
			return nil
		}

		if markers.contains(index) {
			return index..<next
		}
		if let prev = markers.predecessor(of: index) {
			return prev..<next
		}
		return nil
	}
	
	func allSegments() -> [Range<Index>] {
		var segs = [Range<Index>]()
		var start: Index! = nil
		markers.traverse { index in
			if start != nil {
				segs.append(start..<index)
			}
			start = index
		}
		return segs
	}
}

protocol LyricSegmentValidating {
	
	/// Use this to remove unwanted characters in the string.
	/// The replacing segments should be distinct and within the original segment
	func validate(string: Substring) -> [Range<Substring.Index>]
}

class TrimmingWhitespaceValidator: LyricSegmentValidating {
	func validate(string: Substring) -> [Range<Substring.Index>] {
		let condition: (Character) -> Bool = { !($0.isNewline || $0.isWhitespace) }
		guard let first = string.firstIndex(where: condition),
			let last = string.lastIndex(where: condition) else {
				return []
		}
		return [first..<string.index(after: last)]
	}
}
