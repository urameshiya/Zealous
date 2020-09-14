//
//  SongMarkerList.swift
//  Zealous
//
//  Created by Chinh Vu on 8/20/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

typealias FinetuneHandler = (SongMarker, CGFloat) -> Void

struct SongMarkerList: View {
	@ObservedObject var mapping: MarkerMapping
	let timeFormatter: DateComponentsFormatter = {
		let fm = DateComponentsFormatter()
		fm.allowedUnits = [.minute, .second]
		fm.formattingContext = .listItem
		fm.zeroFormattingBehavior = .pad
		return fm
	}()
	let seekHandler: FinetuneHandler
	@Binding var selectedMarker: SongMarker?
	
    var body: some View {
		List(mapping.getSongMarkers(), id: \.self, selection: $selectedMarker) { (marker) in
			SongMarkerCell(
				marker: marker,
				lyric: marker.isEnabled ? self.getLyric(for: marker) : "Instrumental",
				timeFormatter: self.timeFormatter,
				seekHandler: self.seekHandler)
		}
    }
	
	func getLyric(for marker: SongMarker) -> Substring {
		if let range = mapping.getLyricRange(for: marker) {
			return mapping.lyric[range]
		}
		return ""
	}
}


private struct SongMarkerCell: View {
	let marker: SongMarker
	let lyric: Substring
	let timeFormatter: DateComponentsFormatter
	let seekHandler: FinetuneHandler
	@State private var isHovered = false
	
	var body: some View {
		HStack {
			(marker.isEnabled ? Color.purple: Color.gray)
				.frame(width: 10, height: 10)
			Text(String(format: "%.2f", marker.time))
				.frame(width: 50)
			Text(lyric)
				.lineLimit(1)
				.frame(maxWidth: 150, alignment: .leading)
			Group {
				if isHovered {
					FinetuningControl(seekHandler: { offset in
						self.seekHandler(self.marker, offset)
					})
					.layoutPriority(3)
				} else {
					EmptyView()
				}
			}
			Spacer()
		}
		.onHover { self.isHovered = $0 }
	}
}

private struct FinetuningControl: View {
	let seekHandler: (CGFloat) -> Void
	var body: some View {
		HStack {
			SeekButton(label: "--", amount: -0.05)
			SeekButton(label: "-", amount: -0.01)
			SeekButton(label: "+", amount: 0.01)
			SeekButton(label: "++", amount: 0.05)
		}
	}
	
	func SeekButton(label: String, amount: CGFloat) -> some View {
		Button(label: label, amount: amount)
			.onTapGesture { self.seekHandler(amount) }
	}
	
	struct Button: View {
		let label: String
		let amount: CGFloat
		@State private var isHovered = false
		
		var body: some View {
			Text(label)
				.font(Font.system(size: 20))
				.foregroundColor(isHovered ? .red : .white)
				.contentShape(Rectangle())
				.onHover { self.isHovered = $0 }
		}
	}
}
//
//struct SongMarkerList_Previews: PreviewProvider {
//    static var previews: some View {
//        SongMarkerList()
//    }
//}
