//
//  MarkerReachedNotifier.swift
//  Zealous
//
//  Created by Chinh Vu on 8/14/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Combine

class MarkerReachedNotifier: Publisher {
	typealias Output = (position: Int, marker: CGFloat)?
	
	typealias Failure = Never
	
	var markers: [CGFloat] = []
	var player: SongPlayer
	var nextMarker: CGFloat = 0.0
	
	private lazy var sharedPublisher = player.$timeElapsed
		.map { [unowned self] (timeElapsed) in
			return self.getMarker(at: CGFloat(timeElapsed)) }
		.removeDuplicates { $0?.position == $1?.position }
		.share()
	
	var currentMarkerIndex: Int = -1
	var lastPosition: Int?
	var cancellables = Set<AnyCancellable>()
	
	init(player: SongPlayer, markersPublisher: AnyPublisher<[CGFloat], Never>) {
		self.player = player
		unowned let weak_self = self
		markersPublisher.assign(to: \.markers, on: weak_self).store(in: &cancellables)
	}
		
	func getMarker(at time: CGFloat) -> Output {
		assert(-1..<markers.count ~= currentMarkerIndex)
		guard markers.count > 0 else {
			return nil
		}
		if currentMarkerIndex < 0 || markers[currentMarkerIndex] < time {
			var next = currentMarkerIndex + 1
			while next < markers.count && markers[next] <= time {
				next += 1
			} // next is guaranteed to be right after time
			currentMarkerIndex = next - 1
		} else { // marker[index] >= time
			while currentMarkerIndex >= 0 && markers[currentMarkerIndex] > time {
				currentMarkerIndex -= 1
			} // index is right before time
		}
		
		// [index] < time < [index + 1]
		if currentMarkerIndex >= 0 {
			assert(markers[currentMarkerIndex] <= time)
		}
		if currentMarkerIndex < markers.count - 1  {
			assert(markers[currentMarkerIndex + 1] > time)
		}
		return currentMarkerIndex >= 0 ? (currentMarkerIndex, markers[currentMarkerIndex]) : nil
	}
	
	func updateMarkers(_ newMarkers: [CGFloat]) {
		assert(newMarkers.isInIncreasingOrderAndUnique, "array must be sorted")
		markers = newMarkers
	}
	
	func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
		sharedPublisher.receive(subscriber: subscriber)
	}
}
