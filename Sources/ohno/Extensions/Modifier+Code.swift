//
//  Modifier+Code.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Ink
import LilHTML
import Splash

struct CodeNote {
	var lineNumber: Int
	var indentation: String
	var lines: [String] = []

	func content() -> String {
		let content = lines.map { $0.replacing(#/[\s\t]*\/\/\//#, with: "") }
			.joined(separator: "\n")
			.trimmingCharacters(in: .whitespacesAndNewlines)

		return MarkdownParser(modifiers: [
			.init(target: .paragraphs) { _, markdown in
				"""
				<p>\(markdown)</p>
				"""
			},
		]).html(from: content)
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}
}

// Converts `/// CODENOTE!` blocks
struct CodeNoteConverter {
	let input: String

	init(input: String) {
		self.input = input
	}

	func convert() -> (String, [Int: CodeNote]) {
		var result = ""

		var currentCodeNote: CodeNote?
		var codeNotes: [Int: CodeNote] = [:]
		var cleaningUpCodeBlock = false

		var lineNumber = 0
		input.enumerateLines { line, _ in
			if line.starts(with: #/[\s\t]*\/\/\/\sCODENOTE!/#) {
				// Get indentation
				let indentation = (try? #/^([\s\t]*)/#.firstMatch(in: line)?.output.1) ?? ""
				currentCodeNote = CodeNote(lineNumber: lineNumber, indentation: String(indentation))
			} else if line.starts(with: #/[\s\t]*\/\/\//#), var codeNote = currentCodeNote {
				codeNote.lines.append(line)
				currentCodeNote = codeNote
			} else {
				if let codeNote = currentCodeNote {
					codeNotes[lineNumber] = codeNote
					currentCodeNote = nil
					cleaningUpCodeBlock = true
				}

				if cleaningUpCodeBlock, line.isBlank {
					return
				}

				result += line
				result += "\n"
				lineNumber += 1
			}
		}

		// Drop the last newline
		return (String(result.dropLast(1)), codeNotes)
	}
}

extension Modifier {
	static func splashCodeBlocks(withFormat format: HTMLOutputFormat = .init(), context: RenderingContext, didFindImage: ((String) -> Void)? = nil) -> Self {
		let highlighter = SyntaxHighlighter(format: format)

		return Modifier(target: .codeBlocks) { html, markdown in
			let isImage = markdown.contains("!image!")
			let isHiddenImage = markdown.contains("!hidden!")
			var markdown = markdown.dropFirst("```".count)

			guard !markdown.hasPrefix("no-highlight") else {
				return html
			}

			markdown = markdown
				.drop(while: { !$0.isNewline })
				.dropFirst()
				.dropLast("\n```".count)

			if isImage {
				didFindImage?(String(markdown))

				if isHiddenImage {
					return ""
				}
			}

			switch context {
			case .html:
				let (withCodeNotes, codeNotes) = CodeNoteConverter(input: String(markdown)).convert()
				let highlighted = highlighter.highlight(withCodeNotes)

				var lineNumber = 0
				var result = ""

				// Insert code notes into HTML. The lack of newlines is because this happens in a <pre>
				highlighted.enumerateLines { line, _ in
					if let note = codeNotes[lineNumber] {
						let lineWithoutIndentation = line.replacing(#/^[\s\t]*/#, with: "")
						result += """
						<div class="code-note-container">\(note.indentation)<mark class="has-code-note code-note-code" href="#code-note-\(note.lineNumber)" >\(lineWithoutIndentation)</mark>
						"""
						result += """
						<a href="#code-note-\(note.lineNumber)" class="code-note-button" type="button">Show</a><aside class="code-note" id="code-note-\(note.lineNumber)"><div class="code-note-content"><code class="code-note-indentation">\(note.indentation)</code><div>\(note.content())</div></div></aside></div>
						""".trimmingCharacters(in: .whitespacesAndNewlines)
					} else {
						result += line
						result += "\n"
					}

					lineNumber += 1
				}

				return "<pre><code>" + result + "</code></pre>"
			case .rss:
				var result = ""
				// Get rid of code note annotations for RSS readers
				markdown.enumerateLines { line, _ in
					if String(line).starts(with: #/[\s\t]*\/\/\/\sCODENOTE!/#) {
						return
					}

					result += line
					result += "\n"
				}

				// Some RSS readers don't handle tabs well
				result.replace(#/\t/#, with: "  ")

				return "<pre><code>" + highlighter.highlight(String(result)) + "</code></pre>"
			}
		}
	}
}
