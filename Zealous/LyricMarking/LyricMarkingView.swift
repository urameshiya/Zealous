//
//  LyricMarkingView.swift
//  Zealous
//
//  Created by Chinh Vu on 6/24/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import AppKit
import AVKit
import Combine

// Because we can't add highlight underneath otherwise
class TextContainerView: NSView {
	lazy var textView: NSTextView = {
		let view = NSTextView(frame: bounds)
		view.backgroundColor = .clear
		view.isVerticallyResizable = true
		view.isHorizontallyResizable = true
		addSubview(view)
		return view
	}()
	
	override func layout() {
		super.layout()
		textView.sizeToFit()
		frame = textView.bounds
		textView.frame = bounds
	}
	
	override var isFlipped: Bool { // want .zero to be top, like how textview behaves in scrollview
		return true
	}
}

protocol LyricMarkingViewPresentation {
	func show()
	func cleanup()
}

class LyricMarkingView: NSView {
	let workspace: Workspace
	
	private lazy var scrollView: NSScrollView = {
		let view = NSScrollView(frame: bounds)
		view.autoresizingMask = [.height, .width]
		return view
	}()
	
	lazy var textContainerView: TextContainerView = {
		let view = TextContainerView(frame: bounds)
		return view
	}()
	
	var textView: NSTextView {
		textContainerView.textView
	}
	
	var isEditable: Bool = false {
		didSet {
			guard isEditable != oldValue else {
				return
			}
			textView.isEditable = isEditable
			if !isEditable { // reset
				textView.isSelectable = false
				// FIXME: Remove for better way of changing lyrics
				workspace.updateLyric(textView.string)
			}
		}
	}
	
	private var presentation: LyricMarkingViewPresentation?
	private var cancellable: AnyCancellable!
		
	init(workspace: Workspace)  {
		self.workspace = workspace
		super.init(frame: .zero)
		addSubview(scrollView)
		scrollView.documentView = textContainerView
		cancellable = workspace.$lyric
			.receive(on: DispatchQueue.main)
			.sink { [unowned self] (lyric) in
				self.textView.string = lyric
				self.textContainerView.needsLayout = true
		}
		textView.string = workspace.lyric
		textView.isEditable = false
		textView.isSelectable = false
		textView.isRichText = false
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layout() {
		textView.minSize = bounds.size
		super.layout()
	}
	
	var layoutManager: NSLayoutManager {
		textView.layoutManager!
	}
	
	var textContainer: NSTextContainer {
		textView.textContainer!
	}
	
	func changePresentation(to presentation: LyricMarkingViewPresentation) {
		self.presentation?.cleanup()
		self.presentation = presentation
		presentation.show()
	}
}

extension NSLayoutManager {
	
}
