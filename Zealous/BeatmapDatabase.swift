//
//  BeatmapDatabase.swift
//  Zealous
//
//  Created by Chinh Vu on 8/5/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

class BeatmapDatabase {
	let fileManager = FileManager.default
	let directory: URL
	var cachedTitles = [String: Set<String>]() // [Artist: Set<SongTitle>]
	var ext = "json"
	var exporter: BeatmapExporter = LyricExporter()

	init(directory: URL) {
		self.directory = directory
	}
	
	func reload() throws {
		cachedTitles = .init()
		
		for artistPath in try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.nameKey]) {
			let artist = artistPath.lastPathComponent
			var songs = Set<String>()
			for songPath in try fileManager.contentsOfDirectory(at: artistPath,
																includingPropertiesForKeys: [.nameKey],
																options: .skipsHiddenFiles) {
				guard songPath.pathExtension == ext else {
					continue
				}
				songs.insert(songPath.deletingPathExtension().lastPathComponent)
			}
			cachedTitles[artist] = songs
		}
	}
		
	func hasBeatmap(for song: SongResource) -> Bool {
		return cachedTitles[song.artistName ?? unknownArtist]?.contains(song.title) ?? false
	}
	
	private let unknownArtist = "Unknown Artist"
	
	func save(beatmap: Beatmap) throws {
		guard let title = beatmap.title else {
			return
		}
		let artist = beatmap.artist ?? unknownArtist
		let data = try exporter.export(beatmap: beatmap)
		let artistPath = directory
			.appendingPathComponent(artist, isDirectory: true)
		let songPath = artistPath
			.appendingPathComponent(title, isDirectory: false)
			.appendingPathExtension(ext)
		try fileManager.createDirectory(at: artistPath, withIntermediateDirectories: true, attributes: nil)
		try data.write(to: songPath, options: .atomic)
		cachedTitles[artist, default: Set()].insert(title)
	}
}
