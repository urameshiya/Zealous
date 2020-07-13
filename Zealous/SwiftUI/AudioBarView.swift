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
	@State var enabled = true
	
	var body: some View {
		Rectangle()
			.foregroundColor(self.enabled ? Color.blue : Color.red)
			.frame(axis: self.axis, majorLength: Marker.markerHeight)
			.offset(-Marker.markerHeight / 2, along: self.axis)
	}
}

struct Caret: View {
	var axis: Axis
	
	var body: some View {
		Rectangle()
			.foregroundColor(Color.black)
			.frame(axis: self.axis, majorLength: 1)
	}
}

struct Bar: View {
	var axis: Axis
	@ObservedObject var player: SongPlayer
	@State var selectedMarker: Int = -1
	var markerFractions: [CGFloat]
	
	var body: some View {
		ZStack(alignment: .topLeading) {
			GeometryReader { geo in
				Rectangle()
					.foregroundColor(Color.yellow)
				ForEach(self.markerFractions, id: \.self) { fraction in
					Marker(axis: self.axis)
						.offset(geo.length(along: self.axis) * fraction, along: self.axis)
				}
				Caret(axis: self.axis)
					.offset(geo.length(along: self.axis) * CGFloat(self.player.fractionElapsed),
							along: self.axis)
			}
		}
	}
}

struct AudioBarViewUI: View {
	@State var axis: Axis
	@ObservedObject var markingController: SongMarkingController
	var player: SongPlayer
	
	var body: some View {
		Bar(axis: self.axis, player: player, markerFractions: markingController.markerFractions)
			.frame(axis: self.axis, minorLength: 30)
			.padding([.vertical], 20)
	}
}

struct AudioBar_Previews: PreviewProvider {
	static let player = SongPlayer()
    static var previews: some View {
		AudioBarViewUI(axis: .vertical, markingController: SongMarkingController(player: player), player: player)
			.frame(width: 100, height: 300)
    }
}
