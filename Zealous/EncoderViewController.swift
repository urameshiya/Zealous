//
//  EncoderViewController.swift
//  Zealous
//
//  Created by Chinh Vu on 6/24/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import AppKit
import AVKit

class EncoderViewController: NSViewController {
	var player: AVPlayer?
}

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

class LyricMarkingView: NSView {
	lazy var separator = LyricSeparator(lyric: lyric)
	
	private lazy var scrollView: NSScrollView = {
		let view = NSScrollView(frame: bounds)
		view.autoresizingMask = [.height, .width]
		return view
	}()
	
	private lazy var textContainerView: TextContainerView = {
		let view = TextContainerView(frame: bounds)
		return view
	}()
		
	private var textView: NSTextView {
		textContainerView.textView
	}
	
	private var colorPicker = ColorAlternator(colorPool: [#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1), #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1), #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)])
	var highlightViews = [String.Index: NSView]()
	
	override init(frame frameRect: NSRect) {

		super.init(frame: frameRect)
		addSubview(scrollView)
		scrollView.documentView = textContainerView
		textView.string = lyric
		textView.isEditable = false
		let gest = NSClickGestureRecognizer(target: self, action: #selector(didClick(sender:)))
		textView.addGestureRecognizer(gest)
	}
	
	@objc func didClick(sender: NSClickGestureRecognizer) {
		let layoutManager = textView.layoutManager!
		var fraction: CGFloat = 0
		let point = sender.location(in: textView)
		let dist = layoutManager.characterIndex(for: point,
													 in: textView.textContainer!,
													 fractionOfDistanceBetweenInsertionPoints: &fraction)
		let index = String.Index(utf16Offset: dist, in: lyric)
		print(lyric[index])
		
		if let (old, new) = separator.cutSegment(at: fraction < 0.5 ? index: lyric.index(after: index)) {
			removeSegment(withStartIndex: old.lowerBound)
			new.forEach { (segment) in
				positionHighlightView(over: segment)
			}
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layout() {
		textView.minSize = bounds.size
		super.layout()
	}
	
	func removeSegment(withStartIndex startIndex: String.Index) {
		if let view = highlightViews[startIndex] {
			view.removeFromSuperview()
		}
	}
	
	func positionHighlightView(over segment: Range<String.Index>) {
		let frame = textView.layoutManager!.boundingRect(forGlyphRange: NSRange(segment, in:lyric), in: textView.textContainer!)
		let highlight = NSView(frame: textView.convert(frame, to: textContainerView))
		highlight.wantsLayer = true
		let hLayer = highlight.layer!
		hLayer.backgroundColor = colorPicker.randomColor(differentFrom: [.red]).cgColor
		hLayer.opacity = 0.3
		hLayer.cornerRadius = 4
		hLayer.masksToBounds = true
		textContainerView.addSubview(highlight, positioned: .below, relativeTo: textView)
		highlightViews[segment.lowerBound] = highlight
	}
}

extension LyricMarkingView {
	var lyric: String { """
	abcd😄😄😄  pppmo😄😄😄po
	新聞の一面に　僕の名前見出しで
	あんたの気を惹きたい
	今日じゃないと　絶対だめなんだよ
	黄色い線の上　ギリギリのステップで踊っている
	うまいこと染まれないよ　借りもんの個性的じゃ減点
	
	面倒事にノックダウン　一人暮らしはまあキツいです
	表参道から松濤　僕はダンサーインザダーク
	安月給で惨敗　まだ工事終わんないし
	
	好き嫌い　大都会
	
	イヤフォンの向こうで　歌う声に焦がれている
	劣等感、厭世的な気分で朝を待って
	こんな思いを知っても　鼓膜の上であなたが
	クソみたいな現実を一瞬光らせるから、超越した
	
	ねぇ、表は危ないよ
	センセーションなんざくそ喰らえだろ
	あんたの卓越は若さやお金じゃはかれないのに
	名声を強請って　無いもの見栄張ってる
	
	着飾るばかり　都会
	
	イヤフォンの向こうで　叫ぶ声に正されている
	嫌悪感、肯定できない僕が嫌になって
	こんな思いになって尚　“なんとか”を保てるのは
	嘘みたいな理想の何処かあなたがいるから、超越してよ

	五線譜の上のさばる本音　折れそうな僕は神頼みだ
	本当は何も願っていない　うつった癖が直らない
	芸術(アート)なんて音楽なんて
	歌をうたったからなんだって
	絵を描いたって足しにならないから辞めちまえば

	芸術なんて音楽なんて音楽なんて
	音楽なんて音楽なんて音楽なんて　もうくたばれ
	芸術なんて音楽なんて何もなくっていなくなって
	価値をつけて選ばれなくて

	憧れだけ

	イヤフォンの向こうで　歌う声に焦がれている
	劣等感、厭世的な気分で朝を待って
	こんな思いを知っても　鼓膜の上であなたが
	クソみたいな現実だとしても光らせた

	イヤフォンの向こうへ　三分と少しの間だけ
	全能感、革命的な気分でいさせて
	そういつだって指先ひとつで　[再生]
	ありふれた生活　殴り込んであなたは
	クソみたいな現実を　たった一小節で変えて

	超越したの、1LDKで
	"""
	}
}
