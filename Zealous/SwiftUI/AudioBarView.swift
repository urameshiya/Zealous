//
//  AudioBarView.swift
//  Zealous
//
//  Created by Chinh Vu on 7/6/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

struct Marker: View {
	static let markerHeight: CGFloat = 3
	let axis: Axis
	var enabled = true
	var selected: Bool
	
	var body: some View {
		Rectangle()
			.foregroundColor(self.enabled ? Color.blue : Color.red)
			.border(self.selected ? Color.white : .clear)
			.frame(axis: self.axis, majorLength: Marker.markerHeight)
			.offset(-Marker.markerHeight / 2, along: self.axis)
	}
}

struct Caret: View {
	var axis: Axis
	var geo: GeometryProxy
	@ObservedObject var player: SongPlayer
	
	var body: some View {
		Rectangle()
			.foregroundColor(Color.black)
			.frame(axis: self.axis, majorLength: 1)
			.offset(geo.length(along: self.axis) * CGFloat(self.player.fractionElapsed),
					along: self.axis)
	}
}

struct AudioBarControl {
	var removeMarker: (SongMarker) -> Void
}

struct Bar: View {
	var axis: Axis
	var player: SongPlayer
	@State var selectedMarker: Int = -1
	var markers: [SongMarker]
	
	var body: some View {
		ZStack(alignment: .topLeading) {
			GeometryReader { geo in
				Rectangle()
					.foregroundColor(Color.yellow)
				ForEach(0..<self.markers.count, id: \.self) { i in
					Marker(axis: self.axis, selected: i == self.selectedMarker)
						.offset(geo.length(along: self.axis) * self.markers[i].time / CGFloat(self.player.duration),
								along: self.axis)
						.onTapGesture {
							self.selectedMarker = self.selectedMarker == i ? -1 : i
					}
				}
				Caret(axis: self.axis, geo: geo, player: self.player)
			}
		}
	}
}

struct AudioBarViewUI: View {
	@State var axis: Axis
	@ObservedObject var beatmap: Beatmap
	var player: SongPlayer
	
	var body: some View {
		Bar(axis: self.axis, player: player, markers: beatmap.songMarkers)
			.frame(axis: self.axis, minorLength: 30)
			.padding([.vertical], 20)
	}
}

struct AudioBar_Previews: PreviewProvider {
	static let beatmap = Beatmap()
	static let player = SongPlayer()
    static var previews: some View {
		AudioBarViewUI(axis: .vertical, beatmap: beatmap, player: player)
			.frame(width: 100, height: 300)
    }
}
