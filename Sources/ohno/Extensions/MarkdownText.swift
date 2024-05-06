//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot
import Ink
import LilParser

struct MarkdownText: Component {
	var markdown: String

	init(_ markdown: String) {
		self.markdown = markdown
	}

	var html: String {
		let html = MarkdownParser().parse(markdown).html

		// Get rid of the wrapping P
		if let parser = try? Parser(html: html).parse().get(),
			 let paragraph = parser.first(.p) {
			return paragraph.innerHTML
		} else {
			return html
		}
	}

	var body: any Component {
		ComponentGroup(html: html)
	}
}
