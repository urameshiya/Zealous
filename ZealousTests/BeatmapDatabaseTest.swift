//
//  BeatmapDatabaseTest.swift
//  ZealousTests
//
//  Created by Chinh Vu on 8/7/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import XCTest
@testable import Zealous

class BeatmapDatabaseTest: XCTestCase {
	var testDir: URL!
	var database: BeatmapDatabase!
	let fm = FileManager.default
	
	override func setUpWithError() throws {
		testDir = makeTestDirectory()
		database = try .init(directory: testDir)
		database.exporter = MockExporter()
	}
	
	func testSavingBeatmap() throws {
		let bm = Workspace(lyric: "Test")
		bm.title = "Hype Mode"
		bm.artist = "Reol"
		try database.save(workspace: bm)
		try database.save(workspace: bm) // overwrite doesn't throw error
		let saveURL = testDir.appendingPathComponent("Reol/Hype Mode.json")
		XCTAssert(fm.fileExists(atPath: saveURL.path))
	}

	func makeTestDirectory() -> URL {
		let fm = FileManager.default
		let tempDir = fm.temporaryDirectory
		let testDir = tempDir.appendingPathComponent(UUID().uuidString, isDirectory: true)
		addTeardownBlock {
			do {
				try fm.removeItem(at: testDir)
				XCTAssertFalse(fm.fileExists(atPath: testDir.path))
			} catch {
				XCTFail("Unable to remove test directory: \(error)")
			}
		}
		do {
			try fm.createDirectory(at: testDir, withIntermediateDirectories: true, attributes: nil)
		} catch {
			XCTFail("Unable to create test directory: \(error)")
		}
		return testDir
	}
}

final class MockExporter: BeatmapExporter {
	func export(workspace: Workspace) throws -> Data {
		return "Testing".data(using: .utf8)!
	}
}
