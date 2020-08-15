//
//  LyricExporter.swift
//  Zealous
//
//  Created by Chinh Vu on 7/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

protocol BeatmapExporter {
	func export(beatmap: Beatmap) throws -> Data
}

enum ExporterError: Error {
	case noLyricSeparator
}

final class LyricExporter: BeatmapExporter {
	func export(beatmap: Beatmap) throws -> Data {
		guard let lyricSeparator = beatmap.lyricSeparator else {
			throw ExporterError.noLyricSeparator
		}
		let processedLyric = serialize(range: lyricSeparator.segments,
									   distance: lyricSeparator.lyric.distance(from:to:))
		var beats = [BeatmapFile.Beat]()
		var disabledMarkers = [CGFloat]()
		let audioMarkers = beatmap.songMarkers
		var i = 0
		audioMarkers.forEach { (marker) in
			if i < processedLyric.count {
				beats.append(.init(time: marker.time, segment: processedLyric[i]))
				i += 1
			}
		}
		
		let outFile = BeatmapFile(lyric: lyricSeparator.lyric,
								  beatmap: beats,
								  disabledTimes: disabledMarkers)
		let data = try JSONEncoder().encode(outFile)
		return data
	}

}

final class LyricImporter {
	func load(from url: URL) throws -> Beatmap {
		let data = try Data(contentsOf: url)
		let file = try JSONDecoder().decode(BeatmapFile.self, from: data)
		let beatmap = Beatmap()
		let separator = LyricSeparator(lyric: file.lyric)
		deserialize(separator: separator, offsets: file.beatmap.map { $0.segment })
		beatmap.lyricSeparator = separator
		beatmap.songMarkers = file.beatmap.map { .init(time: $0.time) }
		return beatmap
	}
}

private func deserialize(separator: LyricSeparator, offsets: [Range<Int>]) {
	let range = separator.segments
	let lyric = separator.lyric
	var lastIndex = lyric.startIndex
	for segment in offsets {
		let valid = lyric.index(lastIndex, offsetBy: segment.lowerBound)
		let invalid = lyric.index(valid, offsetBy: segment.upperBound)
		range.mark(index: valid, enabled: true)
		range.mark(index: invalid, enabled: false)
		lastIndex = invalid
	}
}

/// lowerbound: offset from the previous segment/length of the invalid segment,
/// upperbound: length of the valid segment
fileprivate func serialize<Index, Distance>(range: GapSegmentedRange<Index>,
								  distance: (Index, Index) -> Distance) -> [Range<Distance>] where Distance: Numeric  {
	var segments = [Range<Distance>]()
	let markers = range.segments.markers
	
	var invalidOffset = Distance.zero
	var lastWereValid = true
	var lastIndex: Index! = nil
	markers.traverse { (marker) in
		guard lastIndex != nil else {
			lastIndex = marker.index
			return
		}
		defer {
			lastWereValid = marker.isValid
			lastIndex = marker.index
		}
		let distance = distance(lastIndex, marker.index)
		guard lastWereValid else {
			invalidOffset += distance
			return
		}
		segments.append(invalidOffset..<distance)
		invalidOffset = 0
	}
	return segments
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
