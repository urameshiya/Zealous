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
			}
		}
	}
	
	private var presentation: LyricMarkingViewPresentation?
		
	init(workspace: Workspace)  {
		self.workspace = workspace
		super.init(frame: .zero)
		addSubview(scrollView)
		scrollView.documentView = textContainerView
		textView.string = lyric
		textView.isEditable = false
		textView.isSelectable = false
		textView.isRichText = true
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

extension LyricMarkingView {
	var lyric: String { """
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

extension NSLayoutManager {
	
}
