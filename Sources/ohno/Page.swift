//
//  Page.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot

protocol WebPage {
    var page: Page { get }
}

struct Page {
    var title: String
    var content: any Component
    var footer: any Component
    var opengraph: OpenGraph?

    init() {
        title = ""
        content = Text("")
        footer = Text("")
    }

    init(title: String, opengraph: OpenGraph? = nil, header _: any Component, content: any Component, footer: any Component) {
        self.title = title
        self.content = content
        self.footer = footer
        self.opengraph = opengraph
    }

    init(
        title: String,
        opengraph: OpenGraph? = nil,
        @ComponentBuilder content: () -> any Component,
        @ComponentBuilder footer: () -> any Component
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
        self.opengraph = opengraph
    }
}
