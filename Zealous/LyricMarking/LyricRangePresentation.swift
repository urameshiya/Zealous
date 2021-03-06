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
	var lyric: String { get }
	func allLyricRanges() -> [Range<String.Index>]
}

protocol SongMarkersProvider {
	var songMarkersDidChange: AnyPublisher<Void, Never> { get }
	func allSongMarkers() -> [SongMarker]
}

protocol LyricRangePresentationDelegate: AnyObject {
	func lyricRangePresentation(_ presentation: LyricRangePresentation, didSelectRange: Range<String.Index>)
}

final class LyricRangePresentation: LyricMarkingViewPresentation, MappingLyricRangeSelector {
	unowned let lyricView: LyricMarkingView
	let colorPicker = ColorAlternator(colorPool: [#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)])
	let rangeContainer: NSView
	fileprivate var highlightViews = [String.Index: HighlightView]()
	private var cancellables = [AnyCancellable]()
	let hitTestView: HitTestForwardingView
	let lyricProvider: LyricRangeProvider
	let songMarkersProvider: SongMarkersProvider
	weak var delegate: LyricRangePresentationDelegate?
	var mode: Mode = .snip

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
		highlightViews[segment.lowerBound] = highlight
	}
	
	func show() {
		recalculateHighlightViews()
		lyricView.textContainerView.addSubview(rangeContainer, positioned: .below, relativeTo: lyricView.textView)
		lyricView.addSubview(hitTestView)
	}
	
	func cleanup() {
		rangeContainer.removeFromSuperview()
		hitTestView.removeFromSuperview()
		control.removeFromSuperview()
	}
	
	var playAlong: LyricPlayAlong?
	
	func recalculateHighlightViews() {
		let ranges = lyricProvider.allLyricRanges()
		for old in highlightViews.values {
			old.removeFromSuperview()
		}
		highlightViews = .init()
		for range in ranges {
			let color = colorPicker.nextColor()
			addHighlightView(over: range, color: color)
		}
	}
	
	private var currentlySelected: HighlightView? {
		didSet {
			oldValue?.isSelected = false
			currentlySelected?.isSelected = true
		}
	}
	
	var selectedRange: Range<String.Index>? {
		return currentlySelected?.range
	}
	
	fileprivate func highlightDidClick(_ view: HighlightView, gesture: NSClickGestureRecognizer) {
		let workspace = lyricView.workspace
		let mapping = workspace.mapping
		
		switch mode {
		case .select:
			currentlySelected = view
			
			if let marker = workspace.mapping.getSongMarker(for: view.range) {
				workspace.player?.seek(to: marker.time)
			}
			delegate?.lyricRangePresentation(self, didSelectRange: view.range)
		case .snip:
			let location = gesture.location(in: lyricView.textView)
			let nearest = lyricView.layoutManager.nearestCharacterIndex(at: location, in: lyricView.textContainer)
			let lyric = mapping.lyric
			
			assert(lyric == lyricView.textView.string)
			
			let splitIndex = lyric.index(lyric.startIndex, offsetBy: nearest)
			if mapping.splitLyricRange(at: splitIndex) {
				removeHighlightView(view: view)
				addHighlightView(over: view.range.lowerBound..<splitIndex, color: view.color)

				var exclColors = [view.color]
				if let next = mapping.allLyricRanges().first(where: { $0.lowerBound > splitIndex }) {
					exclColors.append(highlightViews[next.lowerBound]!.color)
				}
				addHighlightView(over: splitIndex..<view.range.upperBound,
								 color: colorPicker.randomColor(differentFrom: exclColors))
			}
		}
	}
	
	private func removeHighlightView(view: HighlightView) {
		view.removeFromSuperview()
		highlightViews[view.range.lowerBound] = nil
	}
	
	private lazy var control = NSButton(title: "Select Mode", target: self, action: #selector(changeMode))
	
	func makeControl() -> NSView {
		return control
	}
	
	@objc func changeMode() {
		currentlySelected = nil
		switch mode {
		case .select:
			mode = .snip
			control.title = "To Select"
		case .snip:
			mode = .select
			control.title = "To Snip"
		}
	}
	
	enum Mode {
		case select
		case snip
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
	var isSelected = false {
		didSet {
			// Change appearance
			if isSelected {
				beginBlink()
			} else {
				stopBlink()
			}
		}
	}
	var color: NSColor
	
	init(frame frameRect: NSRect,
		 color: NSColor,
		 range: Range<String.Index>,
		 presentation: LyricRangePresentation)
	{
		self.color = color
		self.presentation = presentation
		self.range = range
		super.init(frame: frameRect)
		wantsLayer = true
		let hLayer = layer!
		hLayer.backgroundColor = color.cgColor
		hLayer.opacity = 0.2
		hLayer.cornerRadius = 4
		hLayer.masksToBounds = true
		
		let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(didClick(_:)))
		addGestureRecognizer(clickRecognizer)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@objc func didClick(_ gesture: NSClickGestureRecognizer) {
		presentation.highlightDidClick(self, gesture: gesture)
	}
		
	private func beginBlink() {
		let animation = CABasicAnimation(keyPath: "opacity")
		animation.fromValue = 1.0
		animation.toValue = 0.0
		animation.duration = 0.75
		animation.autoreverses = true
		animation.repeatCount = .greatestFiniteMagnitude
		
		layer?.add(animation, forKey: "blink")
	}
	
	private func stopBlink() {
		layer?.removeAnimation(forKey: "blink")
	}
	
}

final class LyricPlayAlong {
	unowned let presentation: LyricRangePresentation
	private var currentHighlighted: HighlightView?
	var cancellable: Any!
	
	var workspace: Workspace { presentation.lyricView.workspace }
	
	init(presentation: LyricRangePresentation, notifier: MarkerReachedNotifier) {
		self.presentation = presentation
		cancellable = notifier
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: { [unowned self] marker in
				self.highlight(at: marker)
		})
	}
	
	func highlight(at marker: SongMarker?) {
		
		if let old = currentHighlighted {
			old.layer?.opacity = 0.3
			currentHighlighted = nil
		}
		
		guard let marker = marker else {
			return
		}
		
		if let new = workspace.mapping.getLyricRange(for: marker)?.lowerBound,
			let view = presentation.highlightViews[new] {
			view.layer?.opacity = 1.0
			currentHighlighted = view
		}
	}
}
