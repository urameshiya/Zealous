//
//  ContentView.swift
//  Zealous
//
//  Created by Chinh Vu on 6/24/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
		HStack {
			VStack {
				Text("Thumbnail")
					.background(Color.red)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
				Text("Song Title")
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
			
		}
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
