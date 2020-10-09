//
//  MappingCoordinator.swift
//  Zealous
//
//  Created by Chinh Vu on 8/31/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

protocol MappingLyricRangeSelector: AnyObject {
	var selectedRange: Range<String.Index>? { get }
}

protocol MappingSongMarkerSelector: AnyObject {
	var selectedMarker: SongMarker? { get }
}

class MappingCoordinator: LyricRangePresentationDelegate {
	var mapping: MarkerMapping
	var selectedSongMarker: SongMarker?
	var selectedSongMarkerBinding: Binding<SongMarker?>!
	weak var lyricSelector: MappingLyricRangeSelector?
	weak var songSelector: MappingSongMarkerSelector?
	
	init(mapping: MarkerMapping) {
		self.mapping = mapping
		self.selectedSongMarkerBinding = .init(
			get: { [unowned self] in self.selectedSongMarker },
			set: { [unowned self] in self.selectedSongMarker = $0})
	}
	
	@objc func mapCurrentlySelected() {
		guard let lyric = lyricSelector?.selectedRange,
			let song = songSelector?.selectedMarker,
			song.isEnabled else {
				// TODO: Maybe throw error
				print("Need to select a lyric segment and a song marker")
				return
		}
		do {
			try mapping.addAnchor(lyric: lyric.lowerBound, song: song.time)
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
		
	}
}
