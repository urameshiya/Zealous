//
//  SongPlayer.swift
//  Zealous
//
//  Created by Chinh Vu on 7/10/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import AVFoundation
import Combine

protocol SongPlayerDelegate: class {
	func songPlayerStatusDidChanged(status: AVPlayerItem.Status)
}

final class SongPlayer: NSObject, ObservableObject {
	@Published private(set) var timeElapsed: Double = 0
	private(set) var duration: Double = .infinity
	var fractionElapsed: Double {
		return timeElapsed / duration
	}
	var player: AVPlayer
	static let updateInterval = CMTimeMake(value: 1, timescale: 30)
	private var observerToken: Any?
	weak var delegate: SongPlayerDelegate?
	
	override init() {
		player = AVPlayer(playerItem: nil)
		super.init()
		observerToken = player.addPeriodicTimeObserver(forInterval: SongPlayer.updateInterval,
													   queue: nil) { [weak self] timeElapsed in
			self?.timeElapsed = CMTimeGetSeconds(timeElapsed)
		}
	}
	
	func seek(to time: CGFloat) {
		// MARK: Refine timescale here
		// 100 should be enough for 60fps
		player.seek(to: .init(seconds: Double(time), preferredTimescale: 100),
					toleranceBefore: .zero, toleranceAfter: .zero)
	}
	
	func loadSong(from url: URL) {
		let playerItem = AVPlayerItem(url: url)
		loadSong(from: playerItem)
	}
	
	func loadSong(from playerItem: AVPlayerItem) {
		player.replaceCurrentItem(with: playerItem)
		timeElapsed = 0
		duration = .infinity
		playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status),
		options: [.new], context: &player)
	}
	
	convenience init(songURL: URL) {
		self.init()
		loadSong(from: songURL)
	}
	
	@objc func play() {
		player.play()
	}
	
	func toggle() {
		player.rate > 0 ? player.pause() : player.play()
	}
	
	func pause() {
		player.pause()
	}
	
	override func observeValue(forKeyPath keyPath: String?,
							   of object: Any?,
							   change: [NSKeyValueChangeKey : Any]?,
							   context: UnsafeMutableRawPointer?) {
		guard context == &player else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}
		if keyPath == #keyPath(AVPlayerItem.status) {
			let status: AVPlayerItem.Status
			if let statusNumber = change?[.newKey] as? NSNumber {
				status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
			} else {
				status = .unknown
			}
			
			switch status {
			case .failed:
				break
			case .readyToPlay:
				duration = CMTimeGetSeconds(player.currentItem!.duration)
				break
			default:
				break
			}
			delegate?.songPlayerStatusDidChanged(status: status)
		}
	}
}
