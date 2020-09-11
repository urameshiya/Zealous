//
//  MappingCoordinator.swift
//  Zealous
//
//  Created by Chinh Vu on 8/31/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

class MappingCoordinator: LyricRangePresentationDelegate {
	var mapping: MarkerMapping
	var selectedSongMarker: SongMarker?
	var selectedSongMarkerBinding: Binding<SongMarker?>!
	var selectedLyricSegment: String.Index?
	
	init(mapping: MarkerMapping) {
		self.mapping = mapping
		self.selectedSongMarkerBinding = .init(
			get: { [unowned self] in self.selectedSongMarker },
			set: { [unowned self] in self.selectedSongMarker = $0})
	}
	
	@objc func mapCurrentlySelected() {
		guard let lyric = selectedLyricSegment,
			let song = selectedSongMarker,
			song.isEnabled else {
				// TODO: Maybe throw error
				assertionFailure()
				return
		}
		do {
			try mapping.addAnchor(lyric: lyric, song: song.time)
			print("Mapping added")
		} catch {
			assertionFailure()
		}
	}
	
	func deleteSelectedSongMarker() {
		guard let marker = selectedSongMarker else {
			return
		}
		selectedSongMarker = nil
		mapping.removeMarker(song: marker)
	}
	
	func lyricRangePresentation(_ presentation: LyricRangePresentation, didSelectRange range: Range<String.Index>) {
		selectedLyricSegment = range.lowerBound
	}
}
