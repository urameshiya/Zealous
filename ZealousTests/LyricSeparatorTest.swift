//
//  LyricSeparatorTest.swift
//  Zealous
//
//  Created by Chinh Vu on 6/24/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import XCTest

class LyricSeparatorTest: XCTestCase {
	let lyric = """
	らっしゃいな　平は成り
	時が来た　正しい夢現　夜もすがら
	変わりゆくことに恐れなし
	のっぴきならないのは御免
	"""
	
	var separator: LyricSeparator!
	
	override func setUpWithError() throws {
		separator = LyricSeparator(lyric: lyric)
	}

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func testExample() throws {
//		let l = "新聞の一面に　僕の名前見出しで"
//        let s = LyricSeparator(lyric: l)
//		s.splitBySeparator { $0.isWhitespace && !$0.isNewline }
//		let markers = s.markers
//		XCTAssertTrue(markers.map { l[$0] } == ["新聞の一面に", "僕の名前見出しで"])
//    }
	
	func testMarking1() {
//		separator.
	}
	
	func testMarking2() {
	
	}
}
