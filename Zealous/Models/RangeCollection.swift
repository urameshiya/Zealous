//
//  RangeCollection.swift
//  Zealous
//
//  Created by Chinh Vu on 8/22/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

class RangeCollection<Value>: BidirectionalCollection where Value: Comparable {
	typealias Element = Range<Value>
	
	private var markers = MarkerCollection<Value>()
	
	init(markers: MarkerCollection<Value>) {
		self.markers = markers
	}
	
	init(maxRange: Range<Value>) {
		markers.updateMarker(maxRange.lowerBound, enabled: true)
		markers.updateMarker(maxRange.upperBound, enabled: false)
	}
	
	func range(containing value: Value) -> Range<Value>? {
		guard let end = markers.firstIndex(where: { $0.value > value }),
			end != markers.startIndex else {
			return nil
		}
		let prev = markers[end - 1]
		return prev.isEnabled ? prev.value..<markers[end].value : nil
	}
	
	func indexOfRange(withLowerbound lowerbound: Value) -> Index? {
		guard let index = markers.firstIndex(where: { $0.value == lowerbound }),
			markers[index].isEnabled else {
			return nil
		}
		assert(index != markers.endIndex, "Marker endIndex should not be enabled")
		return .init(markerIndex: index)
	}
	
	func removeRange(at index: Index) {
		markers.removeMarker(at: index.markerIndex)
	}
	
	func splitRange(at value: Value) {
		assert(range(containing: value) != nil, "Value is within a disabled range")
		markers.updateMarker(value, enabled: true)
	}
	
	func splitRange(withLowerbound lowerbound: Value,
					into newRanges: (Range<Value>) -> [Range<Value>]) {
		guard let oldRange = range(containing: lowerbound) else {
			assertionFailure("Range with the given lowerbound does not exist")
			return
		}
		
		for range in newRanges(oldRange) {
			assert(range.lowerBound >= oldRange.lowerBound, "Out of bounds")
			assert(range.upperBound <= oldRange.upperBound, "Out of bounds")
			markers.updateMarker(range.lowerBound, enabled: true)
			if range.upperBound != oldRange.upperBound { // make sure it does not affect the neighbor range
				markers.updateMarker(range.upperBound, enabled: false)
			}
		}
	}
	
	func disableRange(withLowerbound lowerBound: Value) {
		guard let i = markers.firstIndex(where: { $0.value == lowerBound }) else {
			assertionFailure("Lowerbound does not exist")
			return
		}
		assert(i < markers.endIndex - 1, "out of bounds")
		
		let next = i + 1
		let nextMarker = markers[next]
		if !nextMarker.isEnabled && next < markers.endIndex - 1 { // "consolidate with the next gap, if any"
			markers.removeMarker(at: i + 1)
		}
		
		if i > markers.startIndex {
			let prevMarker = markers[i - 1]
			if prevMarker.isEnabled {
				markers.removeMarker(at: i)
			}
		}
	}
	
	func join(from range1: Range<Value>, to range2: Range<Value>) {
		fatalError("Not implemented")
	}
	
	func allRanges() -> [Range<Value>] {
		markers
			.enumerated()
			.filter { (i, marker) -> Bool in
				if marker.isEnabled {
					return true
				}
				return false
		}
			.map { (i, marker) in
				return marker.value..<markers[i + 1].value
		}
	}
	
	// MARK: - Collection
	var startIndex: Index { .init(markerIndex: 0) }
	var endIndex: Index { .init(markerIndex: markers.endIndex) }
	
	func index(before i: Index) -> Index {
		let prevIndex = i.markerIndex - 1
		return .init(markerIndex: markers[prevIndex].isEnabled ? prevIndex: prevIndex - 1)
	}
	
	func index(after i: Index) -> Index {
		let nextIndex = i.markerIndex + 1
		return .init(markerIndex: markers[nextIndex].isEnabled ? nextIndex : nextIndex + 1)
	}
	
	subscript(position: Index) -> Range<Value> {
		get {
			return markers[position.markerIndex].value..<markers[position.markerIndex + 1].value
		}
	}
	
	struct Index: Comparable {
		fileprivate var markerIndex: Int
	
		static func < (lhs: Index, rhs: Index) -> Bool {
			return lhs.markerIndex < rhs.markerIndex
		}
	}
	
	struct Marker: Comparable {
		var value: Value
		var isEnabled: Bool
		
		init(value: Value, enabled: Bool) {
			self.value = value
			self.isEnabled = enabled
		}
				
		static func < (lhs: Marker, rhs: Marker) -> Bool {
			return lhs.value < rhs.value
		}

		static func == (lhs: Marker, rhs: Marker) -> Bool {
			return lhs.value == rhs.value
		}
	}
}
