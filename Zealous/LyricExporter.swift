//
//  LyricExporter.swift
//  Zealous
//
//  Created by Chinh Vu on 7/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

protocol BeatmapExporter {
	func export(lyricSeparator: LyricSeparator, audioSegments: GapSegmentedRange<SongMarker>)
}

final class LyricExporter: BeatmapExporter {
	var destination: URL
	
	init(destination: URL) {
		self.destination = destination
	}
	
	func export(lyricSeparator: LyricSeparator, audioSegments: GapSegmentedRange<SongMarker>) {
		let processedLyric = serialize(range: lyricSeparator.segments,
									   distance: lyricSeparator.lyric.distance(from:to:))
		var beats = [BeatmapFile.Beat]()
		var disabledMarkers = [CGFloat]()
		let audioMarkers = audioSegments.segments.markers
		var i = 0
		audioMarkers.traverse { (marker) in
			if marker.isValid, i < processedLyric.count {
				beats.append(.init(time: marker.index.time, segment: processedLyric[i]))
				i += 1
			} else {
				disabledMarkers.append(marker.index.time)
			}
		}
		
		do {
			let outFile = BeatmapFile(lyric: lyricSeparator.lyric,
									  beatmap: beats,
									  disabledTimes: disabledMarkers)
			let data = try JSONEncoder().encode(outFile)
			try data.write(to: destination)
		} catch {
			print("Unable to export lyrics")
			print(error)
		}
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
