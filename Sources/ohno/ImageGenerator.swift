//
//  ImageGenerator.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Cocoa
import Foundation
import ImageIO
import Splash
import SwiftUI
import UniformTypeIdentifiers

typealias HexColor = String

extension NSGraphicsContext {
	convenience init(size: CGSize) {
		let scale: CGFloat = 2

		let context = CGContext(
			data: nil,
			width: Int(size.width * scale),
			height: Int(size.height * scale),
			bitsPerComponent: 8,
			bytesPerRow: 0,
			space: CGColorSpaceCreateDeviceRGB(),
			bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
		)!

		context.scaleBy(x: scale, y: scale)

		self.init(cgContext: context, flipped: false)
	}

	func fill(with color: NSColor, in rect: CGRect) {
		cgContext.setFillColor(color.cgColor)
		cgContext.fill(rect)
	}
}

struct ImageGenerator {
	var code: String

	init(code: String) {
		self.code = code.replacing(#/(\t*)/#) { match in
			Array(repeating: "  ", count: match.output.1.count).joined()
		}
	}

	@MainActor func generate(colors: [TokenType: HexColor], padding: CGFloat = 12) throws -> Data? {
		let fontURL = URL.temporaryDirectory.appending(path: "Font.otf")
		defer {
			try? FileManager.default.removeItem(at: fontURL)
		}

		guard let decoded = Data(base64Encoded: Data(FontBase64.utf8)) else {
			return nil
		}

		try decoded.write(to: fontURL)

		guard let code = code.presence else {
			return nil
		}

		var tokenColors: [TokenType: Splash.Color] = [:]
		for (token, hexString) in colors {
			tokenColors[token] = color(from: hexString)
		}

		let font = Font(path: fontURL.path, size: CGFloat(8))
		let theme = Theme(font: font, plainTextColor: .white, tokenColors: tokenColors)
		let outputFormat = AttributedStringOutputFormat(theme: theme)

		let highlighter = SyntaxHighlighter(format: outputFormat)
		let string = highlighter.highlight(code)

		let stringSize = string.size()
		let contextRect = CGRect(
			x: 0,
			y: 0,
			width: stringSize.width + padding * 2,
			height: stringSize.height + padding * 2
		)

		let view = Text(AttributedString(string))
			.frame(width: stringSize.width + padding * 2, height: stringSize.height + padding * 2)
			.background(SwiftUI.Color(theme.backgroundColor))

		let image = ImageRenderer(content: view)
		image.proposedSize = .init(contextRect.size)
		image.scale = 4.0
		image.isOpaque = true

		guard let nsImage = image.nsImage,
		      let tiffRepresentation = nsImage.tiffRepresentation,
		      let imageRep = NSBitmapImageRep(data: tiffRepresentation),
		      let pngData = imageRep.representation(using: .png, properties: [:])
		else {
			return nil
		}

		return pngData
//
		//		let context = NSGraphicsContext(size: contextRect.size)
		//		NSGraphicsContext.current = context
//
		//		context.fill(with: theme.backgroundColor, in: contextRect)
//
		//		string.draw(in: CGRect(
		//			x: padding,
		//			y: padding,
		//			width: stringSize.width,
		//			height: stringSize.height
		//		))
//
		//		let image = context.cgContext.makeImage()!
		//		let url = URL.temporaryDirectory.appending(path: UUID().uuidString)
//
		//		let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil)!
		//		CGImageDestinationAddImage(destination, image, nil)
		//		CGImageDestinationFinalize(destination)
//
		//		let data = try Data(contentsOf: url)
		//		try FileManager.default.removeItem(at: url)
//
		//		return data
	}

	private func color(from hex: HexColor) -> Splash.Color? {
		let r, g, b, a: CGFloat

		var hexColor = hex.replacing("#", with: "")
		let scanner = Scanner(string: hexColor)
		var hexNumber: UInt64 = 0

		if hex.count == 8 {
			if scanner.scanHexInt64(&hexNumber) {
				r = CGFloat((hexNumber & 0xFF00_0000) >> 24) / 255
				g = CGFloat((hexNumber & 0x00FF_0000) >> 16) / 255
				b = CGFloat((hexNumber & 0x0000_FF00) >> 8) / 255
				a = CGFloat(hexNumber & 0x0000_00FF) / 255

				return Color(red: r, green: g, blue: b, alpha: a)
			}
		} else if hex.count == 6 {
			if scanner.scanHexInt64(&hexNumber) {
				r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
				g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
				b = CGFloat(hexNumber & 0x0000FF) / 255.0

				return Color(red: r, green: g, blue: b, alpha: 1.0)
			}
		}

		return nil
	}
}
