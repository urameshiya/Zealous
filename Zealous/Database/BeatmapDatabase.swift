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
	var importer = LyricImporter()

	init(directory: URL) throws {
		self.directory = directory
		try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
	}
	
	func reload() throws {
		cachedTitles = .init()
		
		for artistPath in try fileManager.contentsOfDirectory(at: directory,
															  includingPropertiesForKeys: [],
															  options: .skipsHiddenFiles) {
			guard artistPath.hasDirectoryPath else {
				continue
			}
			let artist = artistPath.lastPathComponent
			var songs = Set<String>()
			for songPath in try fileManager.contentsOfDirectory(at: artistPath,
																includingPropertiesForKeys: [],
																options: .skipsHiddenFiles) {
				guard songPath.pathExtension == ext else {
					continue
				}
				songs.insert(songPath.deletingPathExtension().lastPathComponent)
			}
			cachedTitles[artist] = songs
		}
	}
	
	func hasBeatmapForSong(title: String, artist: String?) -> Bool {
		return cachedTitles[artist ?? unknownArtist]?.contains(title) ?? false
	}
	
	private let unknownArtist = "Unknown Artist"
	
	func save(workspace: Workspace) throws {
		guard let title = workspace.title else {
			return
		}
		let data = try exporter.export(workspace: workspace)
		let url = try getBeatmapURL(title: title, artist: workspace.artist, create: true)
		try data.write(to: url, options: .atomic)
		cachedTitles[workspace.artist ?? unknownArtist, default: Set()].insert(title)
		// TODO: Reserved characters like :/
	}
	
	func getBeatmapURL(title: String, artist: String?, create: Bool) throws -> URL {
		let artistPath = directory
			.appendingPathComponent(artist ?? unknownArtist, isDirectory: true)
		let url = artistPath
			.appendingPathComponent(title, isDirectory: false)
			.appendingPathExtension(ext)
		if create {
			try fileManager.createDirectory(at: artistPath, withIntermediateDirectories: true, attributes: nil)
		}
		return url
	}
	
	func loadBeatmapForSong(title: String, artist: String?) throws -> MarkerMapping {
		return try importer.load(from: getBeatmapURL(title: title, artist: artist, create: false))
	}
}
