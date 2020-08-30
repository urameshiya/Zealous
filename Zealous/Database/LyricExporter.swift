//
//  LyricExporter.swift
//  Zealous
//
//  Created by Chinh Vu on 7/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

protocol BeatmapExporter {
	func export(workspace: Workspace) throws -> Data
}

enum ExporterError: Error {
	case unbalancedMapping
}

final class LyricExporter: BeatmapExporter {
	func export(workspace: Workspace) throws -> Data {
		let processedLyric = serialize(ranges: workspace.mapping.allLyricRanges(),
									   lyric: workspace.lyric)
		var beats = [BeatmapFile.Beat]()
		let audioMarkers = workspace.mapping.getSongMarkers()
		let disabledMarkers = audioMarkers
			.filter { $0.isEnabled }
			.map { $0.time }
		
		var i = 0
		for marker in audioMarkers {
			if i == processedLyric.count {
				throw ExporterError.unbalancedMapping
			}
			if marker.isEnabled {
				beats.append(.init(time: marker.time, segment: processedLyric[i]))
				i += 1
			}
		}
		
		let outFile = BeatmapFile(lyric: workspace.lyric,
								  beatmap: beats,
								  disabledTimes: disabledMarkers)
		let data = try JSONEncoder().encode(outFile)
		return data
	}

}

final class LyricImporter {
	func load(from url: URL) throws -> MarkerMapping {
		let data = try Data(contentsOf: url)
		let file = try JSONDecoder().decode(BeatmapFile.self, from: data)
		let rangeCollection = deserialize(offsets: file.beatmap.map { $0.segment }, lyric: file.lyric)
		let markerCollection = MarkerCollection<CGFloat>(enabled: file.beatmap.map { $0.time },
														 disabled: file.disabledTimes)
		let mapping = MarkerMapping(lyricMarkers: rangeCollection,
									songMarkers: markerCollection,
									lyric: file.lyric)
		return mapping
	}
}

private func deserialize(offsets: [Range<Int>], lyric: String) -> RangeCollection<String.Index> {
	let markers = MarkerCollection<String.Index>()
	var lastIndex = lyric.startIndex

	for segment in offsets {
		let valid = lyric.index(lastIndex, offsetBy: segment.lowerBound)
		let invalid = lyric.index(valid, offsetBy: segment.upperBound)
		markers.updateMarker(valid, enabled: true)
		markers.updateMarker(invalid, enabled: false)
		lastIndex = invalid
	}
	return markers.rangeView
}

/// lowerbound: offset from the previous segment/length of the invalid segment,
/// upperbound: length of the valid segment
fileprivate func serialize<C: Collection>(ranges: C, lyric: String)
	-> [Range<Int>] where C.Element == Range<String.Index> {
	var lastIndex = lyric.startIndex
	return ranges.map { (segment) in
		defer {
			lastIndex = segment.upperBound
		}
		let offsetFromPrevEnd = lyric.distance(from: lastIndex, to: segment.lowerBound)
		let length = lyric.distance(from: segment.lowerBound, to: segment.upperBound)
		return offsetFromPrevEnd..<length
	}
}

struct BeatmapFile: Codable {
	struct Beat: Codable {
		let time: CGFloat
		let segment: Range<Int>
		
		// Compact storage; avoids repeated keys
		func encode(to encoder: Encoder) throws {
			var container = encoder.unkeyedContainer()
			try container.encode(time)
			try container.encode(segment)
		}
		
		init(time: CGFloat, segment: Range<Int>) {
			self.time = time
			self.segment = segment
		}
		
		init(from decoder: Decoder) throws {
			var container = try decoder.unkeyedContainer()
			time = try container.decode(CGFloat.self)
			segment = try container.decode(Range<Int>.self)
		}
	}
	
	var version: String = "1.0"
	var lyric: String
	
	/**
		Each range represents a valid segment of the lyric.

		- lowerbound is the offset from the end of the last valid segment
		- upperbound is the length of the valid segment
	*/
	var beatmap: [Beat]
	var disabledTimes: [CGFloat]
}
