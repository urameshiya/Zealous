//
//  AudioSeekBar.swift
//  Zealous
//
//  Created by Chinh Vu on 10/1/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

struct AudioSeekBar: View {
	var player: SongPlayer
	var body: some View {
		Rectangle()
			.frame(width: 5)
			.background(Color.gray)
			.overlay(Caret(player: player))
			.onTapWithFractionPosition { (loc) in
				self.player.seek(to: CGFloat(self.player.duration) * loc.y)
		}
	}
}

private struct Caret: View {
	@ObservedObject var player: SongPlayer
	var body: some View {
		GeometryReader { geo in
			Color.red
				.frame(width: geo.size.width, height: 3)
				.offset(x: 0, y: self.getOffset(geo: geo))
				.disabled(true)
			Spacer()
		}
	}
	
	func getOffset(geo: GeometryProxy) -> CGFloat {
		return geo.size.height * CGFloat(self.player.fractionElapsed)
	}
}

class AudioBarPreview: PreviewProvider {
	static var previews: some View {
		AudioSeekBar(player: SongPlayer())
			.frame(height:100)
	}
}
