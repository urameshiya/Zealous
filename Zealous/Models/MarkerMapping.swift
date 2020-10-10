//
//  MarkerMapping.swift
//  Zealous
//
//  Created by Chinh Vu on 8/19/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Combine

enum MarkerMappingError: Error {
	case anchorInWrongOrder(String.Index, CGFloat)
}

struct SongMarker: Comparable, Hashable {
	let time: CGFloat
	let isEnabled: Bool
	
	static func < (lhs: SongMarker, rhs: SongMarker) -> Bool {
		lhs.time < rhs.time
	}
}

final class MarkerMapping: ObservableObject, LyricRangeProvider, SongMarkersProvider {
	typealias SongMarkersCollection = [SongMarker]
	
	private var _songMarkersDidChange = PassthroughSubject<Void, Never>()
	var songMarkersDidChange: AnyPublisher<Void, Never> {
		_songMarkersDidChange.eraseToAnyPublisher()
	}
	
	func allSongMarkers() -> [SongMarker] {
		songMarkers.map { .init(time: $0.value, isEnabled: $0.isEnabled) }
	}
	
	func allLyricRanges() -> [Range<String.Index>] {
		lyricMarkers.allRanges()
	}
	
	func getSongMarkers() -> SongMarkersCollection {
		return songMarkers.map { SongMarker(time: $0.value, isEnabled: $0.isEnabled) }
	}
	
//	typealias Anchor = (RangeCollection<String.Index>.Index, MarkerCollection<CGFloat>.Index)
	typealias Anchor = (String.Index, CGFloat)
	
	private var lyricMarkers: RangeCollection<String.Index>
	
	private var songMarkers = MarkerCollection<CGFloat>()
	
	private(set) var anchors = [Anchor]()
	private var _map = OneToOneDictionary<String.Index, CGFloat>()
	private(set) var lyric: String

	init(lyric: String) {
		self.lyric = lyric
		lyricMarkers = .init(maxRange: lyric.startIndex..<lyric.endIndex)
	}
		
	// TODO: Maybe take arrays instead of shared collections
	init(lyricMarkers: RangeCollection<String.Index>,
		 songMarkers: MarkerCollection<CGFloat>,
		 lyric: String) {
		self.lyricMarkers = lyricMarkers
		self.songMarkers = songMarkers
		self.lyric = lyric
		
		evaluateMatchesIfNeeded()
	}
	
	func updateLyric(_ lyric: String) {
		objectWillChange.send()
		self.lyric = lyric
		lyricMarkers = .init(maxRange: lyric.startIndex..<lyric.endIndex)
		anchors = .init()
		_map = .init()
	}
		
	func addAnchor(lyric: String.Index, song: CGFloat) throws {
		let insertAt = try anchors.firstIndex { (maxString, maxSong) -> Bool in
			if maxString < lyric && maxSong < song {
				return false
			}
			if maxString > lyric && maxSong > song {
				return true
			}
			throw MarkerMappingError.anchorInWrongOrder(maxString, maxSong)
		}
		anchors.insert((lyric: lyric, song: song), at: insertAt ?? anchors.endIndex)
		evaluateMatchesIfNeeded()
	}
	
	func lyricRange(containing stringIndex: String.Index) -> Range<String.Index>? {
		return lyricMarkers.range(containing: stringIndex)
	}
	
	func splitLyricRange(withLowerBound lowerBound: String.Index, using splitter: LyricSegmentProcessing) {
		lyricMarkers.splitRange(withLowerbound: lowerBound) { range in
			splitter
				.process(segment: self.lyric[range])
				.map { $0.startIndex..<$0.endIndex }
		}
		evaluateMatchesIfNeeded()
	}
	
	func splitLyricRange(at stringIndex: String.Index) -> Bool {
		objectWillChange.send()
		
		defer {
			evaluateMatchesIfNeeded()
		}
		return lyricMarkers.splitRange(at: stringIndex)
	}
	
	func addSongMarker(at time: CGFloat, enabled: Bool) {
		songMarkers.updateMarker(time, enabled: enabled)
		evaluateMatchesIfNeeded()
	}
	
	func removeMarker(lyric: String.Index) {
		guard let index = lyricMarkers.indexOfRange(withLowerbound: lyric) else {
			assertionFailure("Not exist")
			return
		}
		lyricMarkers.removeRange(at: index)
		if let anchorIndex = anchors.firstIndex(where: { $0.0 == lyric }) {
			anchors.remove(at: anchorIndex)
		}
		evaluateMatchesIfNeeded()
	}
		
	func removeMarker(song: SongMarker) {
		guard let i = songMarkers.firstIndex(where: { $0.value == song.time }) else {
			assertionFailure("Not exist")
			return
		}
		songMarkers.removeMarker(at: i)
		if let anchorIndex = anchors.firstIndex(where: { $0.1 == song.time }) {
			anchors.remove(at: anchorIndex)
		}
		evaluateMatchesIfNeeded()
	}
	
	/// Toggle between lyric and instrumental
	func changeMarkerType(_ marker: SongMarker) {
		songMarkers.updateMarker(marker.time, enabled: !marker.isEnabled)
		evaluateMatchesIfNeeded()
	}
	
	func nudgeSongMarker(_ marker: SongMarker, by amount: CGFloat, absoluteLimit: Range<CGFloat>) -> CGFloat? {
		objectWillChange.send()
		guard let newTime = songMarkers.nudgeMarker(
			at: songMarkers.firstIndex(where: { $0.value == marker.time })!,
			by: amount,
			absoluteLimit: absoluteLimit) else {
				return nil
		}
		_map[newTime] = _map[marker.time]
		_map[marker.time] = nil
		return newTime
	}
	
	func getLyricRange(for marker: SongMarker) -> Range<String.Index>? {
		if let marker = _map[marker.time] {
			return lyricMarkers.range(containing: marker)!
		}
		return nil
	}
	
	func getSongMarker(for lyric: Range<String.Index>) -> SongMarker? {
		if let time = _map[lyric.lowerBound] {
			return SongMarker(time: time, isEnabled: true)
		}
		return nil
	}
			
	private func evaluateMatchesIfNeeded() {
		objectWillChange.send()
		let (results, _, _) = align(c1: lyricMarkers.lazy.map { $0.lowerBound },
									c2: songMarkers.lazy
										.filter { $0.isEnabled }
										.map { $0.value},
									anchors: anchors)
		_map = .init()
		for mapping in results {
			_map.put(mapping)
		}
	}
	
	private func align<C1: Sequence, C2: Sequence, C3: Sequence>(
		c1: C1,
		c2: C2,
		anchors: C3
	) -> (
		results: [C3.Element],
		unmatchedFirst: [C1.Element],
		unmatchedSecond: [C2.Element]
	) where C1.Element: Equatable, C2.Element: Equatable, C3.Element == (C1.Element, C2.Element) {
		// assume anchors, c1, c2 are sorted

		var results = [(C1.Element, C2.Element)]()
		var unmatchedFirst = [C1.Element]()
		var unmatchedSecond = [C2.Element]()
		var firstIter = c1.makeIterator()
		var secondIter = c2.makeIterator()
		
		for anchor in anchors {
			var first: C1.Element! = firstIter.next()
			var second: C2.Element! = secondIter.next()
			while first != anchor.0 && second != anchor.1 {
				results.append((first, second))
				first = firstIter.next()
				second = secondIter.next()
			}
			while first != anchor.0 {
				unmatchedFirst.append(first)
				first = firstIter.next()
				assert(first != nil)
			}
			
			while second != anchor.1 {
				unmatchedSecond.append(second)
				second = secondIter.next()
				assert(second != nil)
			}
			assert(first == anchor.0 && second == anchor.1)
			results.append((first, second))
		}

		outer: while let first = firstIter.next() {
			while let second = secondIter.next() {
				results.append((first, second))
				continue outer
			}
			unmatchedFirst.append(first)
		}
		
		while let second = secondIter.next() {
			unmatchedSecond.append(second)
		}
		return (results, unmatchedFirst, unmatchedSecond)
	}
}
