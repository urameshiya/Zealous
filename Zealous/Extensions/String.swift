//
//  String.swift
//  Zealous
//
//  Created by Chinh Vu on 7/16/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Foundation

extension Character {
	static let delete: Character = fromInt(NSDeleteCharacter)
	
	private static func fromInt(_ v: Int) -> Character {
		Character(UnicodeScalar(v)!)
	}
}
