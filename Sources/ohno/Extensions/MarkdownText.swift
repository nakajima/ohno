//
//  MarkdownText.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Ink
import LilHTML
import Plot

struct MarkdownText: Component {
	var markdown: String
	var debug: Bool = false

	init(_ markdown: String, debug: Bool = false) {
		self.markdown = markdown
		self.debug = debug
	}

	var html: String {
		let html = MarkdownParser().parse(markdown).html

		// Get rid of the wrapping P
		if let parsed = try? HTML(html: html).parse().get() {
			for p in parsed.find(.p) {
				if p.childNodes.isEmpty {
					p.remove()
				}
			}

			return parsed.innerHTML
		} else {
			return html
		}
	}

	var body: any Component {
		ComponentGroup(html: html)
	}
}
