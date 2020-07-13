//
//  SongSelectionView.swift
//  Zealous
//
//  Created by Chinh Vu on 7/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI
import AVFoundation

struct SongSelectionView: View {
	let songs: [SongResource]
	let onSelected: (SongResource) -> Void
	@State var highlightedRow: Int = -1
	
	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
//			HStack { // Header
//				Text("Song Title")
//				Text("Artist")
//			}
			SongList()
		}
	}
	
	func Column<Content>(@ViewBuilder content: @escaping (Int) -> Content)
		-> some View where Content: View {
			VStack(alignment: .leading) {
				ForEach(0..<songs.count) { i in
					content(i)
				}
			}
	}
	
	func TextRow(_ text: String, row: Int) -> some View {
		Text(text)
			.lineLimit(1)
			.frame(height: 15)
			.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
			.background(row == highlightedRow ? Color.red : .clear)
			.contentShape(Rectangle())
			.onTapGesture {
				self.highlightedRow = row
		}
		.simultaneousGesture(TapGesture(count: 2)
		.onEnded { _ in
			self.onSelected(self.songs[row])
		})
	}
	
	func SongList() -> some View {
		ScrollView(.vertical) {
			HStack(spacing: 2) {
				Column { i in
					self.TextRow(self.songs[i].title, row: i)
				}
				Column { i in
					self.TextRow(self.songs[i].artistName ?? "", row: i)
				}
			}
		}
	}
}

struct SongSelectionView_Previews: PreviewProvider {
	fileprivate static let songs: [Song] = [
		["AAA", "BBB"],
		["ApAOLPOALP", "Okay"],
		["Opp apal", "haapaapevlae"]
	]
	static var previews: some View {
		SongSelectionView(songs: songs) { _ in
			print("Selected")
		}
	}
}

fileprivate struct Song: SongResource, ExpressibleByArrayLiteral {
	var title: String
	
	var artistName: String?
	
	var artworkImage: NSImage? = nil
	
	init(arrayLiteral elements: String?...) {
		title = elements[0]!
		artistName = elements[1]
	}
	
	func load() throws -> AVPlayerItem {
		throw SongResourceError.unavailable
	}
}
