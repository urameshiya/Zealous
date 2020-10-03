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
	let mapButton: NSButton
	let buttonStack: NSStackView
	let masterStack: NSStackView
	let songMarkerView: NSHostingView<SongMarkerList>
	let seekBar: NSHostingView<AudioSeekBar>
	
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
		mapButton = NSButton(title: "Map selected",
							 target: controller.mappingCoordinator,
							 action: #selector(MappingCoordinator.mapCurrentlySelected))
		artworkView = .init()
		buttonStack = .init(views: [artworkView, selectButton,
									exportButton, editButton, markerModeButton, mapButton])
		buttonStack.orientation = .vertical
		lyricView = .init(workspace: controller.workspace)
		songMarkerView = NSHostingView(rootView: SongMarkerList(mapping: controller.workspace.mapping,
																seekHandler: controller.workspace.nudgeSongMarker,
																selectedMarker: controller.mappingCoordinator.selectedSongMarkerBinding))
		seekBar = NSHostingView(rootView: AudioSeekBar(player: controller.player))
		masterStack = .init(views: [lyricView, buttonStack, seekBar, songMarkerView])
		
		super.init(frame: .zero)
		
		editButton.target = self
		editButton.action = #selector(editButtonDidClick)
		
		markerModeButton.target = controller
		markerModeButton.action = #selector(Controller.markerMode)
		
		masterStack.autoresizingMask = [.width, .height]
		masterStack.frame = .zero
		masterStack.translatesAutoresizingMaskIntoConstraints = true
		addSubview(masterStack)
		
		songMarkerView.heightAnchor.constraint(equalTo: masterStack.heightAnchor).isActive = true
		songMarkerView.widthAnchor.constraint(equalToConstant: 300).isActive = true
		seekBar.topAnchor.constraint(equalTo: masterStack.topAnchor, constant: 50).isActive = true
		seekBar.bottomAnchor.constraint(equalTo: masterStack.bottomAnchor, constant: -20).isActive = true
//		seekBar.heightAnchor.constraint(equalToConstant: 200).isActive = true
		
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
//		try! beatmapDatabase.reload()
//		didSelect(song: musicApp.allSongs.first(where: { $0.title == "1LDK" })!)
	}
	
	var player: SongPlayer = SongPlayer()
	
	var musicApp: iTunesService!
	
	var selectionViewHost: NSViewController!
	
	override var acceptsFirstResponder: Bool { true }
	
	var workspace: Workspace = Workspace(lyric: "")
	lazy var mappingCoordinator = MappingCoordinator(mapping: workspace.mapping)
	
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
			workspace.markCurrent()
		case Character.delete:
			mappingCoordinator.deleteSelectedSongMarker()
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

	}
		
	func didSelect(song: SongResource) {
		if let host = self.selectionViewHost {
			self.dismiss(host)
		}
		
		if beatmapDatabase.hasBeatmapForSong(title: song.title, artist: song.artistName) {
			let alert = NSAlert()
			alert.informativeText = "Open existing workspace in database?"
			alert.addButton(withTitle: "Yes")
			alert.addButton(withTitle: "No")
			let result = alert.runModal()
			switch result {
			case .alertFirstButtonReturn:
				do {
					let mapping = try beatmapDatabase.loadBeatmapForSong(title: song.title,
																		 artist: song.artistName)
					workspace.updateMapping(mapping)
					mainView.songMarkerView.rootView = .init(mapping: mapping,
															 seekHandler: workspace.nudgeSongMarker,
															 selectedMarker: mappingCoordinator.selectedSongMarkerBinding)
					mappingCoordinator.mapping = mapping
				} catch {
					// TODO: Throw Error
				}
			default:
				break
			}
		}
		
		do {
			workspace.title = song.title
			workspace.artist = song.artistName
			workspace.player = player
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
			print("Unable to reload workspace database: \(error)")
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
			try beatmapDatabase.save(workspace: workspace)
		} catch {
			print("Unable to save workspace: \(error)")
		}
	}
	
	@objc func play() {
		player.toggle()
	}
	
	@objc func markerMode() {
		let presentation = LyricRangePresentation(view: mainView.lyricView)
		presentation.delegate = mappingCoordinator
		mainView.lyricView.changePresentation(to: presentation)
	}
}
