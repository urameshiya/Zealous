//
//  KeyboardControl.swift
//  Zealous
//
//  Created by Chinh Vu on 7/12/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import AppKit

enum Direction {
	case up, down, left, right
}

enum KeyboardKey {
	case spacebar
//	case arrow(direction: Direction)
	
	init?(rawValue: String) {
		guard rawValue.count == 1 else {
			return nil
		}
		let firstCharacter = rawValue.first!
		switch firstCharacter {
		case " ":
			self = .spacebar
		default:
			return nil
		}
	}
}


