//
//  File.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Cocoa
import Foundation
import ImageIO
import Splash

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
		self.code = code.replacing(#/^\t/#, with: "  ")
	}

	func generate(size: CGSize, colors: [TokenType: HexColor], padding: CGFloat = 12) throws -> Data? {
		guard let fontURL = Bundle.module.url(forResource: "SF-Mono-Regular", withExtension: "otf") else {
			return nil
		}

		var tokenColors: [TokenType: Color] = [:]
		for (token, hexString) in colors {
			tokenColors[token] = color(from: hexString)
		}

		print(colors)

		let font = Font(path: fontURL.path, size: CGFloat(12))
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

		let context = NSGraphicsContext(size: contextRect.size)
		NSGraphicsContext.current = context

		context.fill(with: theme.backgroundColor, in: contextRect)

		string.draw(in: CGRect(
			x: padding,
			y: padding,
			width: stringSize.width,
			height: stringSize.height
		))

		let image = context.cgContext.makeImage()!
		let url = URL.temporaryDirectory.appending(path: UUID().uuidString)

		let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil)!
		CGImageDestinationAddImage(destination, image, nil)
		CGImageDestinationFinalize(destination)

		let data = try Data(contentsOf: url)
		try FileManager.default.removeItem(at: url)

		return data
	}

	private func color(from hex: HexColor) -> Color? {
		let r, g, b, a: CGFloat


		var hexColor = hex.replacing("#", with: "")
		let scanner = Scanner(string: hexColor)
		var hexNumber: UInt64 = 0

		if hex.count == 8 {
			if scanner.scanHexInt64(&hexNumber) {
				r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
				g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
				b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
				a = CGFloat(hexNumber & 0x000000FF) / 255

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
