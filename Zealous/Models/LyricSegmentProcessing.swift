//
//  LyricSegmentProcessing.swift
//  Zealous
//
//  Created by Chinh Vu on 9/6/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

protocol LyricSegmentProcessing {
	func process(segment: Substring) -> [Substring]
}

enum LyricSegmentDefaultProcessor: LyricSegmentProcessing {
	case splitNewline
	case splitWhitespaceAndNewlines
	
	func process(segment: Substring) -> [Substring] {
		switch self {
		case .splitNewline:
			return segment.split(separator: "\n")
				.filter { $0.trimmingCharacters(in: CharacterSet.whitespaces) != "" }
		case .splitWhitespaceAndNewlines:
			return segment.split { (char) -> Bool in
				CharacterSet.whitespacesAndNewlines.contains(char.unicodeScalars.first!)
			}
		}
	}
}
