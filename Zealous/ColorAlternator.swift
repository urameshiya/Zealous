//
//  NSColor+Ext.swift
//  Zealous
//
//  Created by Chinh Vu on 7/4/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import AppKit

class ColorAlternator {
	private var colorPool: [NSColor]
	
	init(colorPool: Set<NSColor>) {
		self.colorPool = .init(colorPool)
		assert(colorPool.count > 2)
	}
	
	func randomColor(differentFrom colors: [NSColor]) -> NSColor {
		assert(colors.count < colorPool.count, "Need more colors in pool")
		var random = Int.random(in: 0..<colorPool.count)
		var color: NSColor
		repeat {
			color = colorPool[random]
			random = (random + 1) % colorPool.count
		} while colors.contains(color)
		return color
	}
}
