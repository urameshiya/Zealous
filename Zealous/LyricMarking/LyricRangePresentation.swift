//
//  LyricRangePresentation.swift
//  Zealous
//
//  Created by Chinh Vu on 7/21/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Combine
import SwiftUI

protocol LyricRangeProvider {
	var lyricRangesDidChange: AnyPublisher<Void, Never> { get }
	var lyric: String { get }
	func allLyricRanges() -> [Range<String.Index>]
}

protocol SongMarkersProvider {
	var songMarkersDidChange: AnyPublisher<Void, Never> { get }
	func allSongMarkers() -> [CGFloat]
}

protocol LyricRangePresentationDelegate: AnyObject {
	func lyricRangePresentation(_ presentation: LyricRangePresentation, didSelectRange: Range<String.Index>)
}

final class LyricRangePresentation: LyricMarkingViewPresentation {
	unowned let lyricView: LyricMarkingView
	let colorPicker = ColorAlternator(colorPool: [#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)])
	let rangeContainer: NSView
	fileprivate var highlightViews = [HighlightView]()
	private var cancellables = [AnyCancellable]()
	let hitTestView: HitTestForwardingView
	let lyricProvider: LyricRangeProvider
	let songMarkersProvider: SongMarkersProvider
	weak var delegate: LyricRangePresentationDelegate?

	init(view: LyricMarkingView) {
		lyricProvider = view.workspace.mapping
		songMarkersProvider = view.workspace.mapping
		self.lyricView = view
		rangeContainer = FlippedNSView(frame: view.textContainerView.bounds)
		rangeContainer.autoresizingMask = [.width, .height]
		hitTestView = HitTestForwardingView(target: rangeContainer)
		hitTestView.frame = lyricView.frame
		hitTestView.autoresizingMask = [.width, .height]
		let workspace = view.workspace
		
		lyricProvider.lyricRangesDidChange.sink { [unowned self] _ in
			self.recalculateHighlightViews()
		}.store(in: &cancellables)
		
		
		workspace.$player.sink { [unowned self] (player) in
			guard let player = player else {
				self.playAlong = nil
				return
			}
			let initialMarkers = self.songMarkersProvider.allSongMarkers()
			let markingNotifier = MarkerReachedNotifier(player: player,
														markersPublisher: Just(initialMarkers)
															.append(self.songMarkersProvider
																.songMarkersDidChange
																.map(self.songMarkersProvider.allSongMarkers))
															.eraseToAnyPublisher())
			self.playAlong = .init(presentation: self, notifier: markingNotifier)
		}.store(in: &cancellables)
	}
	
	func addHighlightView(over segment: Range<String.Index>, color: NSColor) {
		let range = NSRange(segment, in: lyricProvider.lyric)
		let frame = lyricView.layoutManager.boundingRect(forGlyphRange: range, in: lyricView.textContainer)
		let highlight = HighlightView(frame: frame, color: color, range: segment, presentation: self)
		rangeContainer.addSubview(highlight)
		highlightViews.append(highlight)
	}
	
	func show() {
		recalculateHighlightViews()
		lyricView.textContainerView.addSubview(rangeContainer, positioned: .below, relativeTo: lyricView.textView)
		lyricView.addSubview(hitTestView)
	}
	
	func cleanup() {
		rangeContainer.removeFromSuperview()
		hitTestView.removeFromSuperview()
	}
	
	var playAlong: LyricPlayAlong?
	
	func recalculateHighlightViews() {
		let ranges = lyricProvider.allLyricRanges()
		for old in highlightViews {
			old.removeFromSuperview()
		}
		highlightViews = .init()
		for range in ranges {
			let color = colorPicker.nextColor()
			addHighlightView(over: range, color: color)
		}
	}
	
	fileprivate func highlightDidClick(_ view: HighlightView) {
		delegate?.lyricRangePresentation(self, didSelectRange: view.range)
	}
}

class HitTestForwardingView: NSView {
	unowned let target: NSView
	
	init(target: NSView) {
		self.target = target
		super.init(frame: .zero)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func hitTest(_ point: NSPoint) -> NSView? {
		return target.hitTest(convert(point, to: target.superview))
	}
}

private class HighlightView: NSView {
	unowned let presentation: LyricRangePresentation
	let range: Range<String.Index>
	
	init(frame frameRect: NSRect,
		 color: NSColor,
		 range: Range<String.Index>,
		 presentation: LyricRangePresentation)
	{
		self.presentation = presentation
		self.range = range
		super.init(frame: frameRect)
		wantsLayer = true
		let hLayer = layer!
		hLayer.backgroundColor = color.cgColor
		hLayer.opacity = 0.3
		hLayer.cornerRadius = 4
		hLayer.masksToBounds = true
		
		let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(didClick(_:)))
		addGestureRecognizer(clickRecognizer)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@objc func didClick(_ gesture: NSClickGestureRecognizer) {
		presentation.highlightDidClick(self)
	}
}

final class LyricPlayAlong {
	unowned let presentation: LyricRangePresentation
	var currentHighlighted: Int?
	var cancellable: Any!
	
	var workspace: Workspace { presentation.lyricView.workspace }
	
	init(presentation: LyricRangePresentation, notifier: MarkerReachedNotifier) {
		self.presentation = presentation
		cancellable = notifier
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: { [unowned self] (value) in
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
