//
//  LyricExporter.swift
//  Zealous
//
//  Created by Chinh Vu on 7/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

protocol BeatmapExporter {
	func export(lyricSeparator: LyricSeparator, audioSeparator: [Double])
}

final class LyricExporter: BeatmapExporter {
	var destination: URL
	
	init(destination: URL) {
		self.destination = destination
	}
	
	func export(lyricSeparator: LyricSeparator, audioSeparator: [Double]) {
		do {
			let exportStruct = ExportStruct(separator: lyricSeparator, audio: audioSeparator)
			let data = try JSONEncoder().encode(exportStruct)
			try data.write(to: destination)
		} catch {
			print("Unable to export lyrics")
			print(error)
		}
	}
}

fileprivate struct ExportStruct: Codable {
	let lyric: String
	let lyricSegments: [Range<Int>]
	let audioSeparator: [Double]
	
	init(separator: LyricSeparator, audio: [Double]) {
		let lyric = separator.lyric
		var segments = [Range<Int>]()
		
		let markers = separator.segments.segments.markers
		var invalidOffset = 0
		var lastWereValid = true
		var lastIndex = lyric.startIndex
		markers.traverse { (marker) in
			defer {
				lastWereValid = marker.isValid
				lastIndex = marker.index
			}
			let distance = lyric.distance(from: lastIndex, to: marker.index)
			guard lastWereValid else {
				invalidOffset += distance
				return
			}
			segments.append(invalidOffset..<distance)
			invalidOffset = 0
		}
		self.lyricSegments = segments
		self.audioSeparator = audio
		self.lyric = lyric
	}
}
