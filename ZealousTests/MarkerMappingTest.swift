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
	
	func testMapCorrectlyWhenSplit() {
		mapping = .init(lyric: lyric)
		mapping.splitLyricRange(withLowerBound: lyric.startIndex, using: LyricSegmentDefaultProcessor.splitNewline)
		mapping.allLyricRanges().enumerated().forEach { (i, _) in
			mapping.addSongMarker(at: CGFloat(i), enabled: true)
		}
		mapping.allLyricRanges().enumerated().forEach { (i, range) in
			try! mapping.addAnchor(lyric: range.lowerBound, song: CGFloat(i))
		}
		
		let marker1 = SongMarker(time: 1, isEnabled: true)
		let beforeSplit = mapping.getLyricRange(for: marker1)!
		XCTAssert(mapping.splitLyricRange(at: lyric.firstIndex(of: "第")!))
		XCTAssert(mapping.getLyricRange(for: .init(time: 0, isEnabled: true))! == lyric.range(of: "今が一番若いの　"))
		XCTAssert(mapping.getLyricRange(for: marker1)! == beforeSplit)
	}
}
