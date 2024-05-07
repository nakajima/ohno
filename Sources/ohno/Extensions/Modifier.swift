//
//  Modifier.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Ink
import Splash

public extension Modifier {
	static func splashCodeBlocks(withFormat format: HTMLOutputFormat = .init(), didFindImage: @escaping (String) -> Void) -> Self {
		let highlighter = SyntaxHighlighter(format: format)

		return Modifier(target: .codeBlocks) { html, markdown in
			let isImage = markdown.contains("!image!")
			var markdown = markdown.dropFirst("```".count)

			guard !markdown.hasPrefix("no-highlight") else {
				return html
			}

			markdown = markdown
				.drop(while: { !$0.isNewline })
				.dropFirst()
				.dropLast("\n```".count)

			if isImage {
				didFindImage(String(markdown))
			}

			let highlighted = highlighter.highlight(String(markdown))

			return "<pre><code>" + highlighted + "\n</code></pre>"
		}
	}
}
