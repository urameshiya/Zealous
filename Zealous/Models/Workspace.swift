//
//  Workspace.swift
//  Zealous
//
//  Created by Chinh Vu on 7/25/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation
import AVFoundation

class Workspace: ObservableObject {
	@Published var player: SongPlayer?
	private(set) var mapping: MarkerMapping
	var title: String?
	var artist: String?
	@Published private(set) var lyric: String
	
	init(lyric: String) {
		self.mapping = .init(lyric: lyric)
		self.lyric = lyric
	}
	
	func updateLyric(_ lyric: String) {
		mapping.updateLyric(lyric)
	}
	
	func updateMapping(_ mapping: MarkerMapping) {
		self.mapping = mapping
		self.lyric = mapping.lyric
	}
		
	func markCurrent() {
		guard let player = player else {
			return
		}
		let time = CGFloat(player.timeElapsed)
		mapping.addSongMarker(at: time, enabled: true)
	}
	
	func nudgeSongMarker(_ marker: SongMarker, by amount: CGFloat) {
		guard let newTime = mapping.nudgeSongMarker(
			marker,
			by: amount,
			absoluteLimit: 0..<CGFloat(player?.duration ?? .infinity)) else {
				return
		}
		player?.seek(to: newTime)
	}
}
