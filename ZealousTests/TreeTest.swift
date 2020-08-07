//
//  TreeTest.swift
//  ZealousTests
//
//  Created by Chinh Vu on 6/25/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import XCTest

class TreeTest: XCTestCase {
	let rand: [Int] = (0..<1000).map { _ in
		Int.random(in: 0..<1000)
	}
	
	var tree: SimpleBST<Int>!

    override func setUpWithError() throws {
		tree = SimpleBST()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
//	func testCTreePerf() {
//		let cTree = SimpleBST<Int>()
//				self.measure {
//					for i in rand {
//						cTree.insert(i)
//					}
//				}
//	}
	
//	func testArrayPerformance() {
//		var arr = [Int]()
//		arr.reserveCapacity(rand.count)
//		self.measure {
//			for i in rand {
//				arr.append(i)
//			}
//			arr.sort()
//		}
//	}
	
	func testPredecessor() {
		tree.insert(10)
		tree.insert(9)
		tree.insert(20)
		tree.insert(15)
		tree.insert(19)
		tree.insert(4)
		
		print(tree!)
		
		XCTAssertEqual(tree.predecessor(of: 5), 4)
		XCTAssertEqual(tree.predecessor(of: 9), 4)
		XCTAssertEqual(tree.predecessor(of: 15), 10)
		XCTAssertEqual(tree.predecessor(of: 19), 15)
		XCTAssertEqual(tree.predecessor(of: 4), nil)
		XCTAssertEqual(tree.predecessor(of: 20), 19)
	}
	
	func testPredecessorSingle() {
		tree.insert(10)
		
		XCTAssertEqual(tree.predecessor(of: 10), nil)
		XCTAssertEqual(tree.predecessor(of: 9), nil)
		XCTAssertEqual(tree.predecessor(of: 12), 10)

	}
	
	func testSuccessor() {
		tree.insert(10)
		tree.insert(9)
		tree.insert(20)
		tree.insert(15)
		tree.insert(19)
		tree.insert(4)
		
		XCTAssertEqual(tree.successor(of: 8), 9)
		XCTAssertEqual(tree.successor(of: 0), 4)
		XCTAssertEqual(tree.successor(of: 10), 15)
		XCTAssertEqual(tree.successor(of: 15), 19)
	}
	
	func testRemove() {
		tree.insert(10)
		tree.insert(9)
		tree.insert(20)
		tree.insert(15)
		tree.insert(19)
		tree.insert(4)
		
		XCTAssertTrue(tree.contains(9))
		XCTAssertEqual(tree.remove(9), 9)
		XCTAssertFalse(tree.contains(9))
		XCTAssertEqual(tree.predecessor(of: 9), 4)
		XCTAssertEqual(tree.successor(of: 9), 10)
		
		XCTAssertEqual(tree.remove(10), 10)
		XCTAssertEqual(tree.predecessor(of: 15), 4)
		XCTAssertEqual(tree.successor(of: 9), 15)
	}
	
	func testInsertGetRange() {
		XCTAssertEqual(tree.insertGetRange(0), .succeed(nil, nil))
		XCTAssertEqual(tree.insertGetRange(30), .succeed(0, nil))
		
		XCTAssertEqual(tree.predecessor(of: 5), 0)
		XCTAssertEqual(tree.insertGetRange(5), .succeed(0, 30))
	}
	
	func testRemoveWhileTraversingInOrder() {
		tree.insert(10)
		tree.insert(9)
		tree.insert(20)
		tree.insert(15)
		tree.insert(19)
		tree.insert(4)
		
		tree.traverse { i in
			if [9, 10, 15].contains(i) {
				tree.remove(i)
			}
		}
		
		XCTAssertFalse(tree.contains(9))
		XCTAssertFalse(tree.contains(15))
		XCTAssertFalse(tree.contains(10))

	}
	
	struct SuperficialEquality: Comparable {
		var value: Int
		var extra: Int
		
		init(_ value: Int, _ extra: Int) {
			self.value = value
			self.extra = extra
		}
		
		static func < (lhs: TreeTest.SuperficialEquality, rhs: TreeTest.SuperficialEquality) -> Bool {
			lhs.value < rhs.value
		}
	}
	
	func testInsertOrUpdate() {
		let tree = SimpleBST<SuperficialEquality>()
		XCTAssertNil(tree.insertOrUpdate(with: .init(10, 0)))
		XCTAssertNil(tree.insertOrUpdate(with: .init(20, 3)))
		XCTAssertNil(tree.insertOrUpdate(with: .init(40, 4)))
		
		let existing = tree.insertOrUpdate(with: .init(20, 6))
		XCTAssertEqual(existing!.extra, 3)
		XCTAssertEqual(tree.find(.init(20, 15))?.extra, 6)
	}
	
}
