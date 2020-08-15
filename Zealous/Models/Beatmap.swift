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
}
