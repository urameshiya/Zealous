//
//  SwiftUI+Ext.swift
//  Zealous
//
//  Created by Chinh Vu on 7/9/20.
//  Copyright © 2020 urameshiyaa. All rights reserved.
//

import SwiftUI

struct TapGestureWithLocation<Content>: View where Content: View {
	typealias Value = CGPoint
	@State var recognized = false
	var onTapped: (Value) -> Void
	var content: Content
	var body: some View {
		content.gesture(
			DragGesture(minimumDistance: 0, coordinateSpace: .local)
				.onChanged({ (value) in
					if self.recognized {
						return
					}
					self.onTapped(value.startLocation)
					self.recognized = true
				})
				.onEnded { (_) in
					self.recognized = false
				}
		)
	}
}

extension View {
	func onLocationTapGesture(location: @escaping (CGPoint) -> Void) -> some View {
		return TapGestureWithLocation(onTapped: location, content: self)
	}
	
	func onTapWithFractionPosition(location: @escaping (CGPoint) -> Void) -> some View {
		return GeometryReader { geo in
			TapGestureWithLocation(onTapped: { loc in
				location(CGPoint(x: loc.x / geo.size.width, y: loc.y / geo.size.height))
			}, content: self)
		}
	}
}

extension Axis {
	var flipped: Axis {
		return self == .horizontal ? .vertical : .horizontal
	}
}

extension View {
	func frame(axis: Axis,
			   majorLength: CGFloat? = nil,
			   minorLength: CGFloat? = nil,
			   alignment: Alignment = .center) -> some View {
		return axis == .horizontal ? self.frame(width: majorLength,
												height: minorLength,
												alignment: alignment)
			: self.frame(width: minorLength,
						 height: majorLength,
						 alignment: alignment)
	}
	
	func offset(_ offset: CGFloat, along axis: Axis) -> some View {
		return axis == .horizontal ? self.offset(x: offset, y: 0)
			: self.offset(x: 0, y: offset)
	}
}

extension GeometryProxy {
	func length(along axis: Axis) -> CGFloat {
		return axis == .horizontal ? size.width : size.height
	}
}

struct AdaptiveStack<Content>: View where Content: View {
	var axis: Axis
	var content: (Axis) -> Content
	
	init(axis: Axis, @ViewBuilder content: @escaping (Axis) -> Content) {
		self.axis = axis
		self.content = content
	}
	
	var body: some View {
		Group {
			if axis == .horizontal {
				HStack { content(axis) }
			} else {
				VStack { content(axis) }
			}
		}
	}
}
