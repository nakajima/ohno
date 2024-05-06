//
//  MarkdownText.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Ink
import LilParser
import Plot

struct MarkdownText: Component {
    var markdown: String

    init(_ markdown: String) {
        self.markdown = markdown
    }

    var html: String {
        let html = MarkdownParser().parse(markdown).html

        // Get rid of the wrapping P
        if let parsed = try? Parser(html: html).parse().get() {
            return parsed.innerHTML
        } else {
            return html
        }
    }

    var body: any Component {
        ComponentGroup(html: html)
    }
}
