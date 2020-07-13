//
//  SongMarkingController.swift
//  Zealous
//
//  Created by Chinh Vu on 7/13/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

class SongMarkingController: ObservableObject {
	@Published private(set) var markerFractions: [CGFloat] = []
	
	var segments: GapSegmentedRange<CGFloat>
	private var player: SongPlayer
	
	init(player: SongPlayer) {
		segments = .init(maxRange: 0..<CGFloat(player.duration))
		self.player = player
	}
	
	func markCurrent() {
		let marker = CGFloat(player.fractionElapsed)
		segments.mark(index: marker, enabled: true)
		markerFractions.append(marker)
		print("Hmmm")
	}
	
	func disableMarker(at pos: CGFloat) {
		segments.mark(index: pos, enabled: false)
	}
	
	func removeMarker(at pos: CGFloat) {
		if let index = markerFractions.firstIndex(where: { $0 == pos }) {
			segments.removeMarker(at: pos)
			markerFractions.remove(at: index)
		}
	}
}
