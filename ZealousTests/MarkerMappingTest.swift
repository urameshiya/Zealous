//
//  MarkerMappingTest.swift
//  ZealousTests
//
//  Created by Chinh Vu on 8/28/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import XCTest
@testable import Zealous

class MarkerMappingTest: XCTestCase {
	var mapping: MarkerMapping!
	var lyric = """
	今が一番若いの　第六感、六感またがって
	今日は年甲斐ないことしたいの
	予定にないこと　第六感、六感おしえて
	物足りないの　引き合いたいよ　偶然とハートしたい
	"""
	
	func test() {
		mapping = .init(lyric: lyric)
		
		XCTAssert(mapping.splitLyricRange(at: lyric.firstIndex(of: "第")!))
	}
}
