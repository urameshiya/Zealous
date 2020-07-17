//
//  SongMarkingController.swift
//  Zealous
//
//  Created by Chinh Vu on 7/13/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

struct SongMarker: Comparable {
	var fraction: CGFloat
	var time: CGFloat
	
	static func < (lhs: SongMarker, rhs: SongMarker) -> Bool {
		lhs.time < rhs.time
	}
}

class SongMarkingController: ObservableObject {
	@Published private(set) var markers: [SongMarker] = []
	
	var segments: GapSegmentedRange<SongMarker>
	private var player: SongPlayer
	
	init(player: SongPlayer) {
		segments = .init(maxRange: SongMarker(fraction: 0.0, time: 0.0)..<SongMarker(fraction: 1.0, time: CGFloat(player.duration)))
		self.player = player
	}
	
	func markCurrent() {
		let marker = SongMarker(fraction: CGFloat(player.fractionElapsed), time: CGFloat(player.timeElapsed))
		segments.mark(index: marker, enabled: true)
		markers.append(marker)
	}
	
	func disable(marker: SongMarker) {
		assert(segments.segment(containing: marker) != nil, "Marker doesn't exist")
		segments.mark(index: marker, enabled: false)
	}
	
	func remove(marker: SongMarker) {
		if let index = markers.firstIndex(where: { $0 == marker }) {
			segments.removeMarker(at: marker)
			markers.remove(at: index)
		} else {
			assertionFailure("Marker doesn't exist")
		}
	}
	
	func seek(to marker: SongMarker) {
		player.seek(to: marker.time)
		player.pause()
	}
}
