//
//  MarkerCollectionTest.swift
//  ZealousTests
//
//  Created by Chinh Vu on 8/28/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import XCTest
@testable import Zealous

class MarkerCollectionTest: XCTestCase {
	var collection: MarkerCollection<Int>!
	
	override func setUpWithError() throws {
		collection = .init()
	}
	
	func testIndexSubscript() {
		collection.updateMarker(3, enabled: true)
		collection.updateMarker(2, enabled: false)
		collection.updateMarker(6, enabled: true)
		collection.updateMarker(7, enabled: false)
		
		let index = collection.firstIndex { $0.value == 3 }
		XCTAssertEqual(collection[index!].value, 3)
	}
	
	func testInOrder() {
		collection.updateMarker(3, enabled: true)
		collection.updateMarker(2, enabled: false)
		collection.updateMarker(6, enabled: true)
		collection.updateMarker(7, enabled: false)
		
		XCTAssert(collection.isInIncreasingOrderAndUnique)
	}
}
