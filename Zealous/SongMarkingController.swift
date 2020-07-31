//
//  SongMarkingController.swift
//  Zealous
//
//  Created by Chinh Vu on 7/13/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Combine

struct SongMarker: Comparable {
	var time: CGFloat
	
	static func < (lhs: SongMarker, rhs: SongMarker) -> Bool {
		lhs.time < rhs.time
	}
}

class MarkerReachedNotifier: Publisher {
	typealias Output = (position: Int, marker: SongMarker)?
	
	typealias Failure = Never
	
	var markers: [SongMarker] = []
	var player: SongPlayer
	var nextMarker: SongMarker = .init(time: 0.0)
	
	private lazy var sharedPublisher = player.$timeElapsed
		.map { [unowned self] (timeElapsed) in
			return self.getMarker(at: CGFloat(timeElapsed))
		}.filter { [unowned self] result in
			defer {
				self.lastPosition = result?.position
			}
			return result?.position != self.lastPosition
		}.share()
	
	var currentMarkerIndex: Int = -1
	var lastPosition: Int?
	var cancellables = Set<AnyCancellable>()
	
	init(player: SongPlayer, markersPublisher: AnyPublisher<[SongMarker], Never>) {
		self.player = player
		unowned let weak_self = self
		markersPublisher.assign(to: \.markers, on: weak_self).store(in: &cancellables)
	}
		
	func getMarker(at time: CGFloat) -> (position: Int, marker: SongMarker)? {
		assert(-1..<markers.count ~= currentMarkerIndex)
		guard markers.count > 0 else {
			return nil
		}
		if currentMarkerIndex < 0 {
			if time > markers[0].time {
				currentMarkerIndex = 0
				return (0, markers[0])
			}
			return nil
		} else if markers[currentMarkerIndex].time < time {
			var next = currentMarkerIndex + 1
			while next < markers.count && markers[next].time < time {
				next += 1
			} // next is guaranteed to be right after time
			currentMarkerIndex = next - 1
		} else { // marker[index] >= time
			while currentMarkerIndex >= 0 && markers[currentMarkerIndex].time > time {
				currentMarkerIndex -= 1
			} // index is right before time
		}
		
		// [index] < time < [index + 1]
		if currentMarkerIndex >= 0 {
			assert(markers[currentMarkerIndex].time < time)
		}
		if currentMarkerIndex < markers.count - 1  {
			assert(markers[currentMarkerIndex + 1].time > time)
		}
		return currentMarkerIndex >= 0 ? (currentMarkerIndex, markers[currentMarkerIndex]) : nil
	}
	
	func updateMarkers(_ newMarkers: [SongMarker]) {
		assert(newMarkers.isInIncreasingOrder, "array must be sorted")
		markers = newMarkers
	}
	
	func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
		sharedPublisher.receive(subscriber: subscriber)
	}
}


class SongMarkingController: ObservableObject {
	let beatmap: Beatmap
	
	var seekFixedPadding: CGFloat = 2.0
	let player: SongPlayer
	
	init(beatmap: Beatmap, player: SongPlayer) {
		self.beatmap = beatmap
		self.player = player
	}
	
	func markCurrent() {
		let marker = SongMarker(time: CGFloat(player.timeElapsed))
		// keep markers sorted
		// reverse range to be equivalent to append(_:) when inserting at the end
		for i in (0..<beatmap.songMarkers.count).reversed() {
			if beatmap.songMarkers[i] < marker {
				beatmap.songMarkers.insert(marker, at: i + 1)
				return
			}
			if beatmap.songMarkers[i] == marker {
				return
			}
		}
		beatmap.songMarkers.insert(marker, at: 0)
	}
	
	func disable(marker: SongMarker) {
		// FIXME: Disable
	}
	
	func remove(marker: SongMarker) {
		if let index = beatmap.songMarkers.firstIndex(where: { $0 == marker }) {
			beatmap.songMarkers.remove(at: index)
		} else {
			assertionFailure("Marker doesn't exist")
		}
	}
	
	func seek(to marker: SongMarker) {
		player.seek(to: max(0, marker.time - seekFixedPadding))
		player.pause()
	}
}
