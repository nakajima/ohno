//
//  File.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Ink
import Splash

public extension Modifier {
	static func splashCodeBlocks(withFormat format: HTMLOutputFormat = .init()) -> Self {
		let highlighter = SyntaxHighlighter(format: format)

		return Modifier(target: .codeBlocks) { html, markdown in
			var markdown = markdown.dropFirst("```".count)

			guard !markdown.hasPrefix("no-highlight") else {
				return html
			}

			markdown = markdown
				.drop(while: { !$0.isNewline })
				.dropFirst()
				.dropLast("\n```".count)

			let highlighted = highlighter.highlight(String(markdown))
			return "<pre><code>" + highlighted + "\n</code></pre>"
		}
	}
}
