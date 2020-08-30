//
//  SongMarkerList.swift
//  Zealous
//
//  Created by Chinh Vu on 8/20/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

struct SongMarkerList: View {
	@ObservedObject var mapping: MarkerMapping
	let timeFormatter: DateComponentsFormatter = {
		let fm = DateComponentsFormatter()
		fm.allowedUnits = [.minute, .second]
		fm.formattingContext = .listItem
		fm.zeroFormattingBehavior = .pad
		return fm
	}()
	
    var body: some View {
		List(mapping.getSongMarkers(), id: \.self) { (marker) in
			(marker.isEnabled ? Color.purple: Color.gray)
				.frame(width: 10, height: 10)
			Text(self.timeFormatter.string(from: TimeInterval(marker.time))!)
//				.frame(width: 50)
			Text(marker.isEnabled ? "Lyric": "Instrumental")
		}
    }
}
//
//struct SongMarkerList_Previews: PreviewProvider {
//    static var previews: some View {
//        SongMarkerList()
//    }
//}
