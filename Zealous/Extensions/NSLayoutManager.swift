//
//  NSLayoutManager.swift
//  Zealous
//
//  Created by Chinh Vu on 7/19/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

extension NSLayoutManager {
	func nearestCharacterIndex(at point: NSPoint, in container: NSTextContainer) -> Int {
		var fraction: CGFloat = 0
		let index = characterIndex(for: point,
								  in: container,
								  fractionOfDistanceBetweenInsertionPoints: &fraction)
		return fraction < 0.5 ? index : index + 1
	}
}
