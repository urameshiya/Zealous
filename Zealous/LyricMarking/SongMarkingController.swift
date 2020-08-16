//
//  SongMarkingController.swift
//  Zealous
//
//  Created by Chinh Vu on 7/13/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Combine

class SongMarkingController: ObservableObject {
	let beatmap: Beatmap
	
	let player: SongPlayer
	
	init(beatmap: Beatmap, player: SongPlayer) {
		self.beatmap = beatmap
		self.player = player
	}
	
	func markCurrent() {
		let marker = SongMarker(time: CGFloat(player.timeElapsed))
		// keep markers sorted
		// reverse range to be equivalent to append(_:) when inserting at the end
		for i in (0..<beatmap.songMarkers.count).reversed() {
			if beatmap.songMarkers[i] < marker {
				beatmap.songMarkers.insert(marker, at: i + 1)
				return
			}
			if beatmap.songMarkers[i] == marker {
				return
			}
		}
		beatmap.songMarkers.insert(marker, at: 0)
	}
	
	func disable(marker: SongMarker) {
		// FIXME: Disable
	}
	
	func remove(marker: SongMarker) {
		if let index = beatmap.songMarkers.firstIndex(where: { $0 == marker }) {
			beatmap.songMarkers.remove(at: index)
		} else {
			assertionFailure("Marker doesn't exist")
		}
	}
}
