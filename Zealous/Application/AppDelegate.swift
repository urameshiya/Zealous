//
//  AppDelegate.swift
//  Zealous
//
//  Created by Chinh Vu on 6/24/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var window: NSWindow!


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Create the SwiftUI view that provides the window contents.
//		let contentView = ContentView()
		// Create the window and set the content view.
		window = NSWindow(
		    contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
		    styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
		    backing: .buffered, defer: false)
		window.center()
		window.setFrameAutosaveName("Main Window")
//		window.contentView = LyricMarkingView(frame: .zero)
		let vc = MainViewController()
		vc.view.frame = CGRect(x: 200, y: 100, width: NSScreen.main?.frame.width ?? 1000, height: 600)
		window.contentViewController = vc
		window.makeKeyAndOrderFront(nil)
		window.makeFirstResponder(vc)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

}

