//
//  LyricRangePresentation.swift
//  Zealous
//
//  Created by Chinh Vu on 7/21/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Combine

final class LyricRangePresentation: LyricMarkingViewPresentation {
	unowned let lyricView: LyricMarkingView
	var lyric: String { lyricView.beatmap.lyricSeparator!.lyric }
	let colorPicker = ColorAlternator(colorPool: [#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)])
	let rangeContainer: NSView
	fileprivate var highlightViews = [NSView]()
	private var cancellables = [AnyCancellable]()

	init(view: LyricMarkingView) {
		self.lyricView = view
		rangeContainer = FlippedNSView(frame: view.textContainerView.bounds)
		rangeContainer.autoresizingMask = [.width, .height]
		let beatmap = view.beatmap
		
		beatmap.$lyricSeparator.sink { [unowned self] _ in
			self.recalculateHighlightViews()
		}.store(in: &cancellables)
		
		beatmap.$player.sink { [unowned self] (player) in
			guard let player = player else {
				self.playAlong = nil
				return
			}
			let markingNotifier = MarkerReachedNotifier(player: player, markersPublisher: beatmap.$songMarkers.eraseToAnyPublisher())
			self.playAlong = .init(presentation: self, notifier: markingNotifier)
		}.store(in: &cancellables)
	}
	
	func addHighlightView(over segment: Range<String.Index>, color: NSColor) {
		let range = NSRange(segment, in:lyric)
		let frame = lyricView.layoutManager.boundingRect(forGlyphRange: range, in: lyricView.textContainer)
		let highlight = NSView(frame: frame)
		highlight.wantsLayer = true
		let hLayer = highlight.layer!
		hLayer.backgroundColor = color.cgColor
		hLayer.opacity = 0.3
		hLayer.cornerRadius = 4
		hLayer.masksToBounds = true
		rangeContainer.addSubview(highlight)
		highlightViews.append(highlight)
	}
	
	func show() {
		lyricView.textContainerView.addSubview(rangeContainer, positioned: .below, relativeTo: lyricView.textView)
	}
	
	func cleanup() {
		rangeContainer.removeFromSuperview()
	}
	
	var playAlong: LyricPlayAlong?
	
	func recalculateHighlightViews() {
		guard let separator = lyricView.beatmap.lyricSeparator else {
			return
		}
		let ranges = separator.allSegments()
		for old in highlightViews {
			old.removeFromSuperview()
		}
		highlightViews = .init()
		for range in ranges {
			let color = colorPicker.nextColor()
			addHighlightView(over: range, color: color)
		}
	}
}

final class LyricPlayAlong {
	unowned let presentation: LyricRangePresentation
	var currentHighlighted: Int?
	var cancellable: Any!
	
	init(presentation: LyricRangePresentation, notifier: MarkerReachedNotifier) {
		self.presentation = presentation
		cancellable = notifier.sink(receiveValue: { [unowned self] (value) in
			self.highlight(at: value?.position)
		})
	}
	
	func highlight(at index: Int?) {
		if let old = currentHighlighted {
			let view = presentation.highlightViews[old]
			view.layer?.opacity = 0.3
		}
		if let new = index {
			let view = presentation.highlightViews[new]
			view.layer?.opacity = 1.0
		}
		currentHighlighted = index
	}
}
