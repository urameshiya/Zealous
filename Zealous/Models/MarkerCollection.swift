//
//  MarkerCollection.swift
//  Zealous
//
//  Created by Chinh Vu on 8/21/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

// A collection of enabled/disabled markers.
class MarkerCollection<Value>: RandomAccessCollection where Value: Comparable {
	typealias Element = Marker
	private(set) var array = [Marker]() {
		willSet {
			assert(array.isInIncreasingOrderAndUnique)
		}
	}
	
	var rangeView: RangeCollection<Value> {
		return .init(markers: self)
	}
	
	var startIndex: Int { return array.startIndex }
	var endIndex: Int { return array.endIndex }
	
	init() {}
	
	init(enabled: [Value], disabled: [Value]) {
		array.reserveCapacity(enabled.count + disabled.count)
		array.append(contentsOf: enabled.map { Marker(value: $0, enabled: true) })
		array.append(contentsOf: disabled.map { Marker(value: $0, enabled: false) })
		array.sort()
	}
	
	func index(after i: Int) -> Int {
		return i + 1
	}
	
	subscript(position: Int) -> Marker {
		get {
			return array[position]
		}
		set {
			array[position] = newValue
		}
	}
			
	func updateMarker(_ value: Value, enabled: Bool) {
		let i = (array.lastIndex { $0.value < value } ?? -1) + 1
		if i != array.endIndex && array[i].value == value {
			array[i].isEnabled = enabled
			return
		}
		array.insert(.init(value: value, enabled: enabled), at: i)
	}
	
	func removeMarker(_ value: Value) -> Marker? {
		let i = array.firstIndex { $0.value == value }
		if let i = i {
			return array.remove(at: i)
		} else {
			return nil
		}
	}
	
	func removeMarker(at index: Int) {
		array.remove(at: index)
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

extension MarkerCollection.Marker: Hashable where Value: Hashable {}

extension MarkerCollection where Value: Strideable {
	// Does not invalidate indices
	func nudgeMarker(at position: Int, by amount: Value.Stride, absoluteLimit: Range<Value>) -> Value? {
		assert(0..<array.count ~= position)
		let newValue = array[position].value.advanced(by: amount)
		
		let prev = position > 0 ? array[position - 1].value : absoluteLimit.lowerBound
		let next = position < array.count - 1
			? array[position + 1].value
			: absoluteLimit.upperBound
		
		guard prev..<next ~= newValue else {
			return nil
		}
		
		array[position].value = newValue
		return newValue
	}
}
