//
//  OneToOneDictionary.swift
//  Zealous
//
//  Created by Chinh Vu on 8/23/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

class OneToOneDictionary<Key: Hashable, Value: Hashable> {
	private var forward = [Key: Value]()
	private var backward = [Value: Key]()
	
	subscript(_ key: Key) -> Value? {
		get {
			return forward[key]
		}
		set {
			if let oldValue = forward[key] {
				backward[oldValue] = nil
			}
			forward[key] = newValue
			if let value = newValue {
				backward[value] = key
			}
		}
	}
	
	subscript(_ value: Value) -> Key? {
		get {
			return backward[value]
		}
		set {
			if let oldKey = backward[value] {
				forward[oldKey] = nil
			}
			backward[value] = newValue
			if let key = newValue {
				forward[key] = value
			}
		}
	}
	
	func put(_ pair: (Key, Value)) {
		self[pair.0] = pair.1
	}
}
