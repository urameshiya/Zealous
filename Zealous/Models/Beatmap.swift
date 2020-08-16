//
//  Beatmap.swift
//  Zealous
//
//  Created by Chinh Vu on 7/25/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation
import AVFoundation

class Beatmap: ObservableObject {
	@Published var lyricSeparator: LyricSeparator?
	@Published var songMarkers: [SongMarker] = []
	@Published var player: SongPlayer?
	var title: String?
	var artist: String?
	
	/// The nudge is unsuccessful if the new time would overstep adjacent markers
	func nudgeSongMarker(at position: Int, by amount: CGFloat) -> Bool {
		assert(0..<songMarkers.count ~= position)
		let newTime = songMarkers[position].time + amount
		
		let prev = position > 0 ? songMarkers[position - 1].time : 0
		let next = position < songMarkers.count - 1
			? songMarkers[position + 1].time
			: CGFloat(player?.duration ?? .infinity)
		
		if newTime < prev || newTime > next {
			return false
		}
		
		songMarkers[position].time = newTime
		return true
	}
	
	func markCurrent() {
		guard let player = player else {
			return
		}
		let marker = SongMarker(time: CGFloat(player.timeElapsed))
		// keep markers sorted
		// reverse range to be equivalent to append(_:) when inserting at the end
		for i in (0..<songMarkers.count).reversed() {
			if songMarkers[i] < marker {
				songMarkers.insert(marker, at: i + 1)
				return
			}
			if songMarkers[i] == marker {
				return
			}
		}
		songMarkers.insert(marker, at: 0)
	}
	
	func disable(marker: SongMarker) {
		// FIXME: Disable
	}
	
	func remove(marker: SongMarker) {
		if let index = songMarkers.firstIndex(where: { $0 == marker }) {
			songMarkers.remove(at: index)
		} else {
			assertionFailure("Marker doesn't exist")
		}
	}
}

struct SongMarker: Comparable {
	var time: CGFloat
	
	static func < (lhs: SongMarker, rhs: SongMarker) -> Bool {
		lhs.time < rhs.time
	}
}
