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

struct SongSelectionView: View {
	let beatmapDatabase: BeatmapDatabase
	let songs: [SongResource]
	let onSelected: (SongResource) -> Void
	@State var highlightedRow: Int = -1
	let search: SearchProcessor
	
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
			TextField("Search", text: search.query)
			SearchTableView(search: search,
							database: beatmapDatabase,
							onSelected: self.onSelected)
		}
	}
}

class SearchTableViewCoordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
	enum Column: String {
		case title = "Title"
		case artist = "Artist"
		case hasBeatmap = "Exists"
		
		init(tableColumn: NSTableColumn) {
			self.init(rawValue: tableColumn.identifier.rawValue)!
		}
	}
	let search: SearchProcessor
	let database: BeatmapDatabase
	let tableView = NSTableView()
	var cancellable: Any?
	let selectionHandler: (SongResource) -> Void
	
	init(search: SearchProcessor,
		 database: BeatmapDatabase,
		 onSelected: @escaping (SongResource) -> Void) {
		self.search = search
		self.database = database
		selectionHandler = onSelected
		super.init()
		tableView.dataSource = self
		tableView.delegate = self
		tableView.target = self
		tableView.doubleAction = #selector(rowDoubleClicked(sender:))
		
		addColumn(.hasBeatmap, width: 20)
		addColumn(.title)
		addColumn(.artist)
		
		tableView.usesAlternatingRowBackgroundColors = true
		
		cancellable = search.$results
			.sink { [unowned self] _ in
				// Reload table at next runloop so @Published change is seen during reload
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
		}
	}

	private func addColumn(_ column: Column, width: CGFloat = 100) {
		let tCol = NSTableColumn(identifier: .init(column.rawValue))
		tCol.title = column.rawValue
		tCol.width = width
		tableView.addTableColumn(tCol)
	}
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return search.results.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let cell: NSTableCellView
		let textField: NSTextField
		
		if let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView {
			cell = view
			textField = view.textField!
		} else {
			// configure cell
			textField = NSTextField()
			cell = NSTableCellView()
			cell.identifier = tableColumn!.identifier
			cell.addSubview(textField)
			cell.textField = textField
			
			textField.frame = cell.bounds
			textField.autoresizingMask = [.width, .height]
			textField.isEditable = false
			textField.isBezeled = false
			textField.drawsBackground = false
		}
				
		let song = search.results[row]
		
		switch Column(tableColumn: tableColumn!) {
		case .title:
			textField.stringValue = song.title
		case .artist:
			textField.stringValue = song.artistName ?? ""
		case .hasBeatmap:
			textField.stringValue = database.hasBeatmapForSong(title: song.title, artist: song.artistName) ? "Y": ""
		}
		return cell
	}
	
	@objc func rowDoubleClicked(sender: Any?) {
		guard tableView.clickedRow > -1 && tableView.clickedRow < search.results.count else { return }
		selectionHandler(search.results[tableView.clickedRow])
	}
}

struct SearchTableView: NSViewRepresentable {
	let search: SearchProcessor
	let database: BeatmapDatabase
	let onSelected: (SongResource) -> Void

	func makeNSView(context: Context) -> NSScrollView {
		let scrollView = NSScrollView()
		let tbView = context.coordinator.tableView
		scrollView.documentView = tbView
		scrollView.hasVerticalScroller = true
		return scrollView
	}
	
	func makeCoordinator() -> SearchTableViewCoordinator {
		return .init(search: search, database: database, onSelected: onSelected)
	}
	
	func updateNSView(_ nsView: NSScrollView, context: Context) {
		
	}
}
