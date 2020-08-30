//
//  Collection.swift
//  Zealous
//
//  Created by Chinh Vu on 7/22/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

extension Sequence where Element: Comparable {
	var isInIncreasingOrderAndUnique: Bool {
		var prev: Element?
		return self.allSatisfy { (cur) -> Bool in
			defer {
				prev = cur
			}
			if let prev = prev {
				return cur > prev
			}
			return true
		}
	}
}
