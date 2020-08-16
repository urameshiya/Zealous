//
//  FinetuningPopover.swift
//  Zealous
//
//  Created by Chinh Vu on 8/15/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

struct FinetuningPopover: View {
	let seekHandler: (CGFloat) -> Void
	
	var body: some View {
		HStack {
			SeekButton(by: -0.01)
			SeekButton(by: -0.05)
			SeekButton(by: +0.05)
			SeekButton(by: +0.01)
		}.background(Color.purple)
	}
	
	func SeekButton(by amount: CGFloat) -> some View {
		Button(action: {
			self.seekHandler(amount)
		}, label: {
			Text(String(format: "%+.2f", amount))
		})
	}
}
