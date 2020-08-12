//
//  SeachProcessor.swift
//  Zealous
//
//  Created by Chinh Vu on 8/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class SearchProcessor: ObservableObject {
	@Published var results: [SongResource]
	private let querySubject = CurrentValueSubject<String, Never>("")
	private(set) var query: Binding<String>!
	
	let songs: [SongResource]
	private var cancellable: AnyCancellable!
	
	init(songs: [SongResource]) {
		self.songs = songs
		results = songs
		query = .init(get: { self.querySubject.value },
					  set: { (query) in
						self.querySubject.send(query)
		})
		cancellable = querySubject
			.map { query in
				let query = query.lowercased()
				return self.songs
					.filter { song in
						song.title.lowercased().starts(with: query)
							|| song.artistName?.lowercased().starts(with: query) ?? false
				}
			}.receive(on: DispatchQueue.main)
			.sink(receiveValue: { [unowned self] (results) in
				self.results = results
			})
	}
}
