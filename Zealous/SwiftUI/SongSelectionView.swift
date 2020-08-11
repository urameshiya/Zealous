//
//  SongSelectionView.swift
//  Zealous
//
//  Created by Chinh Vu on 7/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI
import AVFoundation
import Combine

final class SearchProcessor: ObservableObject {
	@Published var results: [Int]
	private let querySubject = CurrentValueSubject<String, Never>("")
	private(set) var query: Binding<String>!
	
	let songs: [SongResource]
	private var cancellable: AnyCancellable!
	
	init(songs: [SongResource]) {
		self.songs = songs
		results = [Int](0..<songs.count)
		query = .init(get: { self.querySubject.value },
					  set: { (query) in
						self.querySubject.send(query)
		})
		cancellable = querySubject
//			.debounce(for: 0.3, scheduler: DispatchQueue.global(qos: .userInteractive))
			.map { query in
				// TODO: make search items lowercased
				return self.songs
					.enumerated()
					.filter { i, song in
						song.title.starts(with: query)
							|| song.artistName?.starts(with: query) ?? false
				}.map { $0.offset }
			}.receive(on: DispatchQueue.main)
			.sink(receiveValue: { (results) in
				self.results = results
			})
		
	}
}

struct SongSelectionView: View {
	let beatmapDatabase: BeatmapDatabase
	let songs: [SongResource]
	let onSelected: (SongResource) -> Void
	@State var highlightedRow: Int = -1
	@ObservedObject var search: SearchProcessor
	
	init(beatmapDatabase: BeatmapDatabase,
		 songs: [SongResource],
		 onSelected: @escaping (SongResource) -> Void) {
		search = .init(songs: songs)
		self.beatmapDatabase = beatmapDatabase
		self.songs = songs
		self.onSelected = onSelected
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
//			HStack { // Header
//				Text("Song Title")
//				Text("Artist")
//			}
			TextField("Search", text: search.query)
			SongList()
		}
	}
	
	func Column<Content>(@ViewBuilder content: @escaping (Int) -> Content)
		-> some View where Content: View {
			VStack(alignment: .leading) {
				ForEach(search.results, id: \.self) { i in
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
					self.TextRow(
						self.beatmapDatabase.hasBeatmapForSong(title: self.songs[i].title,
															   artist: self.songs[i].artistName) ? "Y" : " ",
						row: i)
						.frame(width: 20, alignment: .center)
				}
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
//		SongSelectionView(songs: songs) { _ in
//			print("Selected")
//		}
		EmptyView()
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
	
	func loadPlayerItem() throws -> AVPlayerItem {
		throw SongResourceError.unavailable
	}
}
