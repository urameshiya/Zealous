//
//  MainViewController.swift
//  Zealous
//
//  Created by Chinh Vu on 7/6/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import AppKit
import AVFoundation
import SwiftUI

extension NSViewController {
	convenience init(view: NSView) {
		self.init()
		self.view = NSView()
		self.view.addSubview(view)
	}
}

class MainViewController: NSViewController, SongPlayerDelegate {
	lazy var selectButton = NSButton(title: "Select song from iTunes", target: self,
								action: #selector(selectDidClick(sender:)))
	lazy var playButton = NSButton(title: "Play song", target: player,
								   action: #selector(SongPlayer.play))
	lazy var exportButton = NSButton(title: "Export", target: self, action: #selector(export))
	
	var audioBar: NSHostingView<AudioBarViewUI>!
	
	let lyricMarkingView = LyricMarkingView()
	
	var stackview = NSStackView()
	
	let songArtworkView = NSImageView()
	
	@objc func export() {
		let outURL = URL(fileURLWithPath: "Documents/test.json")
		LyricExporter(destination: outURL).export(lyricSeparator: lyricMarkingView.separator, audioSeparator: [1, 2, 3])
	}
	
	private var monitorToken: Any?
	
	override func loadView() {
		self.view = NSView()
		audioBar = NSHostingView(rootView: AudioBarViewUI(axis: .vertical,
														  markingController: SongMarkingController(player: player),
														  player: player))
		
		
		songArtworkView.widthAnchor.constraint(equalToConstant: 100).isActive = true
		songArtworkView.heightAnchor.constraint(equalToConstant: 100).isActive = true
		
		let buttonStack = NSStackView(views: [songArtworkView, selectButton, playButton, exportButton])
		buttonStack.orientation = .vertical
		
		stackview = NSStackView(views: [lyricMarkingView, buttonStack, audioBar])
		stackview.autoresizingMask = [.width, .height]
		stackview.frame = view.bounds
		stackview.translatesAutoresizingMaskIntoConstraints = true
		view.addSubview(stackview)
		
		audioBar.heightAnchor.constraint(equalTo: stackview.heightAnchor).isActive = true
		audioBar.widthAnchor.constraint(equalToConstant: 100).isActive = true
		
		// Text View lose focus when tap outside
		monitorToken = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] (event) -> NSEvent? in
			guard let self = self else {
				return event
			}
			let point = event.locationInWindow
			if !self.lyricMarkingView.frame.contains(point) {
				self.view.window?.makeFirstResponder(self)
			}
			return event
		}
		
		do {
			musicApp = try iTunesService()
		} catch {
			print("Cannot initialize itunes library")
			print(error)
		}
		
		player.delegate = self
	}
	
	var player: SongPlayer = SongPlayer()
	
	var musicApp: iTunesService!
	
	var selectionViewHost: NSViewController!
	
	@objc func selectDidClick(sender: NSButton) {
		let selectionView = SongSelectionView(songs: musicApp.allSongs) { [weak self] song in
			self?.didSelect(song: song)
		}
		
		selectionViewHost = NSHostingController(rootView: selectionView)
		selectionViewHost.view.frame = CGRect(x: 0, y: 0, width: 500, height: 700)
		presentAsModalWindow(selectionViewHost)
	}
	
	func didSelect(song: SongResource) {
		if let host = self.selectionViewHost {
			self.dismiss(host)
		}
		do {
			try player.loadSong(from: song.load())
			songArtworkView.image = song.artworkImage
		} catch {
			print("Unable to load song")
			print(error)
		}
	}
	
	override var acceptsFirstResponder: Bool { true }
	
	var songMarkingController: SongMarkingController?
		
	override func keyDown(with event: NSEvent) {
//		print("Keydown \(event.characters)")
		switch event.characters?.first {
		case " ":
			player.toggle()
		case "a", "s", "d":
			songMarkingController?.markCurrent()
		default:
			nextResponder?.keyDown(with: event)
		}
	}
	
	func songPlayerStatusDidChanged(status: AVPlayerItem.Status) {
		switch status {
		case .failed:
			print("Failed to load file")
		case .readyToPlay:
			songMarkingController = .init(player: player)
			audioBar.rootView = .init(axis: .vertical,
									  markingController: songMarkingController!,
									  player: player)
		default:
			break
		}
	}
}
