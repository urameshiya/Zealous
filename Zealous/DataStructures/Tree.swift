//
//  Tree.swift
//  Zealous
//
//  Created by Chinh Vu on 6/25/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

protocol TreeProtocol {
	associatedtype Element: Comparable
	
	func insert(_ element: Element) -> Bool
	
	func traverse(inorder handler: (Element) throws -> Void) rethrows
	
	func predecessor(of value: Element) -> Element?
	
	func successor(of value: Element) -> Element?
	
	func remove(_ x: Element) -> Element?
	
	func contains(_ x: Element) -> Bool
	
	func insertOrUpdate(with element: Element) -> Element?
}

/// Unbalanced; duplicates are not inserted and are reported
class SimpleBST<Element>: CustomStringConvertible, TreeProtocol where Element: Comparable {
	
	var description: String {
		return root.debugDescription
	}
	
	enum InsertionResult: Equatable {
		case duplicated(existing: Element)
		case succeed(_ predecessor: Element?, _ successor: Element?)
	}
		
	private var root: Node?
	private(set) var count: Int = 0
	
	@discardableResult
	func insert(_ x: Element) -> Bool {
		guard let root = root else {
			self.root = Node(x)
			count += 1
			return true
		}
		if let _ = root.insert(x) {
			return false // dupe
		}
		count += 1
		return true
	}
	
	/// returns old element if exists
	func insertOrUpdate(with element: Element) -> Element? {
		guard let root = root else {
			self.root = Node(element)
			count += 1
			return nil
		}
		if let oldElement = root.insertOrUpdate(element) {
			return oldElement // no inserting
		}
		count += 1
		return nil
	}
	
	func predecessor(of value: Element) -> Element? {
		return root?.predecessor(of: value)?.value
	}
	
	func successor(of value: Element) -> Element? {
		return root?.successor(of: value)?.value
	}
	
	func traverse(inorder handler: (Element) throws -> Void) rethrows {
		try root?.traverse(inorder: handler)
	}
	
	func insertGetRange(_ x: Element) -> InsertionResult {
		guard let root = root else {
			self.root = Node(x)
			count += 1
			return .succeed(nil, nil)
		}
		var result = root.insertGetRange(x)
		switch result {
		case .duplicated:
			return result
		case .succeed(nil, let suc):
			result = .succeed(root.predecessor(of: x)?.value, suc)
		case .succeed(let pre, nil):
			result = .succeed(pre, root.successor(of: x)?.value)
		default: // either suc or pre must be nil
			assertionFailure()
		}
		count += 1
		return result
	}
	
	/// Returns removed element if successful
	@discardableResult
	func remove(_ x: Element) -> Element? {
		if let (newRoot, removed) = root?.remove(x) {
			root = newRoot
			count -= 1
			return removed
		}
		return nil
	}
	
	func find(_ x: Element) -> Element? {
		return root?.find(x)?.value
	}
	
	func contains(_ x: Element) -> Bool {
		return root?.find(x) != nil
	}
		
	class Node {
		var left: Node?
		var right: Node?
		var value: Element
		
		init(_ data: Element) {
			self.value = data
		}
		
		// returns the existing element
		func insert(_ x: Element) -> Element? {
			if x < value {
				if let left = left {
					return left.insert(x)
				} else {
					left = Node(x)
				}
			} else if x > value {
				if let right = right {
					return right.insert(x)
				} else {
					right = Node(x)
				}
			} else {
				return value // duplicates
			}
			return nil
		}
		
		func insertOrUpdate(_ x: Element) -> Element? {
			if x < value {
				if let left = left {
					return left.insertOrUpdate(x)
				} else {
					left = Node(x)
				}
			} else if x > value {
				if let right = right {
					return right.insertOrUpdate(x)
				} else {
					right = Node(x)
				}
			} else {
				defer {
					value = x
				}
				return value // duplicates
			}
			return nil
		}
		
		func traverse(inorder handler: (Element) throws -> Void) rethrows {
			try left?.traverse(inorder: handler)
			try handler(value)
			try right?.traverse(inorder: handler)
		}
		
		func predecessor(of x: Element) -> Node? {
			if value >= x { // current node is bigger -> predec. must be in left subtree
				return left?.predecessor(of: x)
			} else {
				// if no right node, predecessor must be currentNode
				// if right subtree exists, closer-to-`value` predecessor may be found in right subtree
				// where currentNode < predecessor < value.
				// If found, this is the predecessor with the currentNode as root.
				return right?.predecessor(of: x) ?? self
			}
		}
		
		func successor(of x: Element) -> Node? {
			if value <= x { // successor must be in the right subtree
				return right?.successor(of: x)
			} else { // successor is in the left subtree, or the current node
				return left?.successor(of: x) ?? self
			}
		}
		
		/// Pre-fills either predecessor or successor
		func insertGetRange(_ x: Element) -> InsertionResult {
			if x < value {
				if let left = left {
					return left.insertGetRange(x)
				} else {
					left = Node(x)
					return .succeed(nil, value) // Fill in predecessor later
				}
			} else if x > value {
				if let right = right {
					return right.insertGetRange(x)
				} else {
					right = Node(x)
					return .succeed(value, nil)
				}
			} else {
				return .duplicated(existing: value) // duplicates
			}
		}
		
		func find(_ x: Element) -> Node? {
			return x < value ? left?.find(x) : (x > value ? right?.find(x) : self)
		}
		
		func remove(_ x: Element) -> (root: Node?, removed: Element?) {
			if x < value {
				if let (root, removed) = left?.remove(x) {
					left = root
					return (self, removed)
				}
			} else if x > value {
				if let (root, removed) = right?.remove(x) {
					right = root
					return (self, removed)
				}
			} else {
				guard let left = left else {
					return (right, value)
				}
				guard let _ = right else {
					return (left, value)
				}
				let pre = left.predecessor(of: value)!
				defer {
					value = pre.value
				}
				(self.left, _) = left.remove(pre.value)
				return (self, value)
			}
			return (self, nil)
		}
		
		var debugDescription: String {
			return "value: \(value), left = [" + left.debugDescription + "], right = [" + right.debugDescription + "]"
		}
	}
}

func ~=<T>(pattern: (T, T) -> Bool, value: (T, T)) -> Bool {
	return pattern(value.0, value.1)
}


