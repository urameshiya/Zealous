//
//  iTunes.swift
//  Zealous
//
//  Created by Chinh Vu on 7/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import iTunesLibrary
import AVFoundation

enum SongResourceError: Error {
	case unavailable
}

protocol SongResource {
	var title: String { get }
	var artistName: String? { get }
	var artworkImage: NSImage? { get }
	
	func loadPlayerItem() throws -> AVPlayerItem
}

class iTunesService {
	private let library: ITLibrary
	let allSongs: [SongResource]
	
	init() throws {
		library = try ITLibrary(apiVersion: "1.0")
		allSongs = library.allMediaItems.filter { $0.mediaKind == .kindSong }
	}
}

extension ITLibMediaItem: SongResource {
	var artistName: String? {
		return artist?.name
	}
	
	var artworkImage: NSImage? {
		return artwork?.image
	}
	
	func loadPlayerItem() throws -> AVPlayerItem {
		guard let location = location else {
			throw SongResourceError.unavailable
		}
		guard location.startAccessingSecurityScopedResource() else {
			assertionFailure("Cannot request access to resource at \(location)")
			throw SongResourceError.unavailable
		}
		defer {
			location.stopAccessingSecurityScopedResource()
		}
		return AVPlayerItem(url: location)
	}
}
