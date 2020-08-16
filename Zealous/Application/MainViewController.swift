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

// MARK: - View

private class MainView: NSView {
	typealias Controller = MainViewController
	let lyricView: LyricMarkingView
	let artworkView: NSImageView
	let selectButton: NSButton
	let editButton: NSButton
	let exportButton: NSButton
	let markerModeButton: NSButton
	let buttonStack: NSStackView
	let masterStack: NSStackView
	var audioBarView: NSHostingView<AnyView>?
	
	private var monitorToken: Any?
	
	init(controller: MainViewController) {
		selectButton = NSButton(title: "Select song from iTunes",
								target: controller,
								action: #selector(Controller.selectDidClick))
		exportButton = NSButton(title: "Export",
								target: controller,
								action: #selector(Controller.export))
		editButton = NSButton(title: "Edit lyric", target: nil, action: nil)
		markerModeButton = NSButton(title: "Marker Mode", target: nil, action: nil)
		artworkView = .init()
		buttonStack = .init(views: [artworkView, selectButton,
									exportButton, editButton, markerModeButton])
		buttonStack.orientation = .vertical
		lyricView = .init(beatmap: controller.beatmap)
		masterStack = .init(views: [lyricView, buttonStack])
		
		super.init(frame: .zero)
		
		editButton.target = self
		editButton.action = #selector(editButtonDidClick)
		
		markerModeButton.target = self
		markerModeButton.action = #selector(markerMode)
		
		masterStack.autoresizingMask = [.width, .height]
		masterStack.frame = .zero
		masterStack.translatesAutoresizingMaskIntoConstraints = true
		addSubview(masterStack)
		
		artworkView.widthAnchor.constraint(equalToConstant: 100).isActive = true
		artworkView.heightAnchor.constraint(equalToConstant: 100).isActive = true

		monitorToken = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) {
			[weak self, weak controller] (event) -> NSEvent? in

			guard let self = self, let controller = controller else {
				return event
			}
			let point = event.locationInWindow
			if !self.lyricView.frame.contains(point) {
				self.window?.makeFirstResponder(controller)
			}
			return event
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func showAudioBar<V: View>(_ bar: V) {
		if let audioBarView = audioBarView {
			audioBarView.rootView = AnyView(bar)
		} else {
			audioBarView = .init(rootView: AnyView(bar))
			masterStack.addArrangedSubview(audioBarView!)
			audioBarView!.heightAnchor.constraint(equalTo: masterStack.heightAnchor).isActive = true
			audioBarView!.widthAnchor.constraint(equalToConstant: 100).isActive = true
		}
	}
	
	func update(with song: SongResource) {
		artworkView.image = song.artworkImage
	}
	
	@objc func editButtonDidClick() {
		lyricView.isEditable.toggle()
		if lyricView.isEditable {
			editButton.title = "Done"
			editButton.keyEquivalent = "\r" // blue background
		} else {
			editButton.title = "Edit lyric"
			editButton.keyEquivalent = ""
		}
	}
	
	@objc func markerMode() {
		lyricView.changePresentation(.segment)
	}
}

// MARK: - View Controller
class MainViewController: NSViewController, SongPlayerDelegate {
	private var mainView: MainView {
		view as! MainView
	}
		
	override func loadView() {
		self.view = MainView(controller: self)
		
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
	
	override var acceptsFirstResponder: Bool { true }
	
	var beatmap: Beatmap = Beatmap()
	
	let beatmapDatabase = try! BeatmapDatabase(directory: FileManager.default.url(for: .documentDirectory,
																				  in: .userDomainMask,
																				  appropriateFor: nil,
																				  create: true)
		.appendingPathComponent("Zeal/Beatmaps"))
		
	override func keyDown(with event: NSEvent) {
//		print("Keydown \(event.characters)")
		switch event.characters?.first {
		case " ":
			player.toggle()
		case "a", "s", "d":
			beatmap.markCurrent()
		case Character.delete:
			// TODO: Delete
			print("Deleted")
			break
		default:
			nextResponder?.keyDown(with: event)
		}
	}
	
	func songPlayerStatusDidChanged(status: AVPlayerItem.Status) {
		switch status {
		case .failed:
			print("Failed to load file")
		case .readyToPlay:
			reloadAudioBar()
		default:
			player.pause()
		}
	}
	
	func reloadAudioBar() {
		mainView.showAudioBar(AudioBarViewUI(axis: .vertical,
											 beatmap: beatmap,
											 player: player))
	}
		
	func didSelect(song: SongResource) {
		if let host = self.selectionViewHost {
			self.dismiss(host)
		}
		
		if beatmapDatabase.hasBeatmapForSong(title: song.title, artist: song.artistName) {
			let alert = NSAlert()
			alert.informativeText = "Open existing beatmap in database?"
			alert.addButton(withTitle: "Yes")
			alert.addButton(withTitle: "No")
			let result = alert.runModal()
			switch result {
			case .alertFirstButtonReturn:
				do {
					let beatmap = try beatmapDatabase.loadBeatmapForSong(title: song.title,
														   artist: song.artistName)
					self.beatmap.lyricSeparator = beatmap.lyricSeparator
					self.beatmap.songMarkers = beatmap.songMarkers
				} catch {
					// TODO: Throw Error
				}
			default:
				break
			}
		}
		
		do {
			beatmap.title = song.title
			beatmap.artist = song.artistName
			beatmap.player = player
			try player.loadSong(from: song.loadPlayerItem())
			mainView.update(with: song)
		} catch {
			print("Unable to load song")
			print(error)
		}
	}
	
	// MARK: - View Delegate
	
	@objc func selectDidClick() {
		do {
			try beatmapDatabase.reload()
		} catch {
			print("Unable to reload beatmap database: \(error)")
		}
		
		let selectionView = SongSelectionView(beatmapDatabase: beatmapDatabase, songs: musicApp.allSongs) { [weak self] song in
			self?.didSelect(song: song)
		}
		
		selectionViewHost = NSHostingController(rootView: selectionView)
		selectionViewHost.view.frame = CGRect(x: 0, y: 0, width: 500, height: 700)
		presentAsModalWindow(selectionViewHost)
	}
	
	@objc func export() {
		do {
			try beatmapDatabase.save(beatmap: beatmap)
		} catch {
			print("Unable to save beatmap: \(error)")
		}
	}
	
	@objc func play() {
		player.toggle()
	}
}
