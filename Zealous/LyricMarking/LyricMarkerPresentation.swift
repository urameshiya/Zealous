//
//  LyricMarkerPresentation.swift
//  Zealous
//
//  Created by Chinh Vu on 7/18/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import AppKit

class MarkerView: NSView {
//	unowned var presenter: LyricMarkerPresentation
	var index: Int
	init(index: Int) {
		self.index = index
		super.init(frame: .zero)
		wantsLayer = true
		layer?.backgroundColor = NSColor.yellow.cgColor
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

final class LyricMarkerPresentation: LyricMarkingViewPresentation {
	unowned var lyricView: LyricMarkingView
	let markerContainerView: NSView
	var markers = [Int: MarkerView]()
	var dragDrop: MarkerDragDropTransaction!
	
	init(lyricView: LyricMarkingView) {
		self.lyricView = lyricView
		markerContainerView = FlippedNSView(frame: lyricView.textContainerView.bounds)
		dragDrop = .init(presentation: self)
	
		markerContainerView.autoresizingMask = [.width, .height]
	}
	
	func addMarker(at point: CGPoint) {
		let index = layoutManager.nearestCharacterIndex(at: point, in: textContainer)
		guard markers[index] == nil else {
			return
		}
		let characterBounds = layoutManager.boundingRect(forGlyphRange: NSRange(location: index, length: 1),
														 in: textContainer)
		let marker = MarkerView(index: index)
		markerContainerView.addSubview(marker)
		marker.frame = CGRect(origin: characterBounds.origin, size: CGSize(width: 3, height: 16))
		dragDrop.configure(marker: marker)
		markers[index] = marker
		print("Added frame: \(marker.frame)")
	}
	
	var layoutManager: NSLayoutManager {
		lyricView.textView.layoutManager!
	}
	
	var textContainer: NSTextContainer {
		lyricView.textView.textContainer!
	}
	
	func textViewDidClick(at point: CGPoint) {
		addMarker(at: point)
	}
	
	func repositionMarker(_ marker: MarkerView, at point: CGPoint) {
		let index = layoutManager.nearestCharacterIndex(at: point, in: textContainer)
		
		// Remove moved marker if one already exists at destination
		guard markers[index] == nil else {
			markers[marker.index] = nil
			marker.removeFromSuperview()
			return
		}
		let rect = layoutManager.boundingRect(forGlyphRange: NSRange(location: index, length: 1), in: textContainer)
		updateMarkerIndex(marker, to: index)
		marker.frame = .init(origin: rect.origin, size: CGSize(width: 3, height: 16))
		print("Moved frame: \(marker.bounds)")
	}
	
	private func updateMarkerIndex(_ marker: MarkerView, to newIndex: Int) {
		markers[marker.index] = nil
		marker.index = newIndex
		markers[newIndex] = marker
	}
	
	func show() {
		lyricView.textContainerView.addSubview(markerContainerView)
	}
	
	func cleanup() {
		markerContainerView.removeFromSuperview()
	}
	
	func workspaceDidChange() {
		// TODO: Recalculate highlight views
	}
}

// MARK: - Drag Drop
class MarkerDragDropTransaction: NSResponder {
	enum UserInfoKey: Hashable {
		case view
	}
	
	var activeMarker: MarkerView?
	var containerView: NSView {
		presentation.lyricView
	}
	unowned let presentation: LyricMarkerPresentation
		
	init(presentation: LyricMarkerPresentation) {
		self.presentation = presentation
		super.init()
		let trackingArea = NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeAlways, .inVisibleRect],
										  owner: self, userInfo: nil)
		containerView.addTrackingArea(trackingArea)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func configure(marker: MarkerView) {
		let userInfo: [AnyHashable: Any] = [UserInfoKey.view: marker]
		let trackingArea = NSTrackingArea(rect: .zero, options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
										  owner: self, userInfo: userInfo)
		marker.addTrackingArea(trackingArea)
		let gesture = NSClickGestureRecognizer(target: self, action: #selector(markerDidClick(gesture:)))
//		marker.addGestureRecognizer(gesture)
	}
	
	private func getMarker(_ event: NSEvent) -> MarkerView {
		return event.trackingArea?.userInfo?[UserInfoKey.view] as! MarkerView
	}
	
	private func getUserInfo(_ event: NSEvent) -> [AnyHashable: Any] {
		return event.trackingArea!.userInfo!
	}
	
	override func mouseEntered(with event: NSEvent) {
		guard activeMarker == nil else {
			return
		}
		let marker = getMarker(event)
		NSAnimationContext.runAnimationGroup { (ctx) in
			ctx.duration = 0.2
			marker.animator().frame = marker.frame.insetBy(dx: -2.0, dy: -5.0)
		}
	}
	
	override func mouseExited(with event: NSEvent) {
		guard activeMarker == nil else {
			return
		}
		let marker = getMarker(event)
		NSAnimationContext.runAnimationGroup { (ctx) in
			ctx.duration = 0.2
			marker.animator().frame = marker.frame.insetBy(dx: 2.0, dy: 5.0)
		}
	}
	
	override func mouseMoved(with event: NSEvent) {
		guard activeMarker != nil else {
			return
		}
		updateActiveMarkerPosition(windowLocation: event.locationInWindow)
	}
	
	func endTransaction() {
		activeMarker = nil
	}
	
	func updateActiveMarkerPosition(windowLocation: NSPoint) {
		let point = activeMarker!.superview!.convert(windowLocation, from: nil)
		let bounds = activeMarker!.bounds
		let center = NSPoint(x: point.x - bounds.midX, y: point.y - bounds.midY) // centers marker at cursor
		activeMarker!.setFrameOrigin(center)
	}
	
	@objc func markerDidClick(gesture: NSClickGestureRecognizer) {
		if let activeMarker = activeMarker {
			endTransaction()
			presentation.repositionMarker(activeMarker, at: gesture.location(in: activeMarker.superview))
		} else {
			activeMarker = (gesture.view as? MarkerView)
			updateActiveMarkerPosition(windowLocation: gesture.location(in: nil))
		}
	}
}

class FlippedNSView: NSView {
	override var isFlipped: Bool {
		return true
	}
}
