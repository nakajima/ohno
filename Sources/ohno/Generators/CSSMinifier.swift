//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/16/24.
//

import Foundation

func measure<T>(_ msg: String, block: () -> T) -> T {
	let start = CFAbsoluteTimeGetCurrent()
	let value = block()
	let diff = CFAbsoluteTimeGetCurrent() - start
	print("\(msg): \(diff) sec.")
	return value
}

struct CSSMinifier {
	static let spaceCharacter = Character(" ")
	static let tabCharacter = Character("\t")
	static let newlineCharacter = Character("\n")
	static let slashCharacter = Character("/")
	static let starCharacter = Character("*")
	static let atCharacter = Character("@")
	static let colonCharacter = Character(":")
	static let semicolonCharacter = Character(";")
	static let leftBraceCharacter = Character("{")
	static let rightBraceCharacter = Character("}")
	static let singleQuoteCharacter = Character("'")
	static let doubleQuoteCharacter = Character("\"")

	let css: String
	let length: Int
	var stream: [Character]
	var position = 0
	var result: [Character] = []

	init(css: String) {
		self.css = css
		self.length = css.count
		self.stream = Array(css)
	}

	static func minify(css: String) -> String {
		var minifier = CSSMinifier(css: css)
		return minifier.minified()
	}

	mutating func next() -> Character? {
		if position >= length {
			return nil
		}

		let character = stream[position]

		position += 1

		return character
	}

	func peek(offset: Int = 0) -> Character? {
		let peekPosition = position + offset

		if peekPosition >= length - 1 {
			return nil
		}

		return stream[peekPosition]
	}

	mutating func minified() -> String {
		var respectWhitespace = false

		outer: while let nextChar = next() {
			switch nextChar {
			case Self.tabCharacter: continue
			case Self.newlineCharacter: continue
			case Self.slashCharacter: // Strip comments
				if peek() == Self.starCharacter {
					while let nextCommentChar = next() {
						if nextCommentChar == Self.starCharacter && peek() == Self.slashCharacter {
							_ = next() // Consume final "/"
							break
						}
					}
				} else {
					result.append(nextChar)
				}
			case Self.atCharacter:
				respectWhitespace = true
				result.append(nextChar)
			case Self.colonCharacter:
				consumeWhitespace()
				respectWhitespace = true
				result.append(nextChar)
			case Self.semicolonCharacter:
				respectWhitespace = true
				result.append(nextChar)
				consumeWhitespace()
			case Self.leftBraceCharacter:
				consumeWhitespace()
				respectWhitespace = true
				result.append(nextChar)
			case Self.rightBraceCharacter:
				consumeWhitespace()
				respectWhitespace = true
				result.append(nextChar)
			case _ where Self.singleQuoteCharacter == nextChar || Self.doubleQuoteCharacter == nextChar: // Don't strip from strings
				result.append(nextChar)

				// Don't mess with strings
				while let nextStringChar = next(), nextStringChar != nextChar {
					result.append(nextStringChar)
				}

				result.append(nextChar)
			case Self.spaceCharacter:
				// We never want more than one space
				consumeWhitespace()

				// But keep one if we're respecing it, unless the next character
				// is just starting a ruleset
				if respectWhitespace, peek() != Self.leftBraceCharacter {
					result.append(nextChar)
				}
			default:
				result.append(nextChar)
			}
		}

		return String(result)
	}

	mutating func consumeWhitespace() {
		while let char = peek(), char == Self.tabCharacter || char == Self.spaceCharacter || char == Self.newlineCharacter {
			_ = self.next()
		}
	}
}
