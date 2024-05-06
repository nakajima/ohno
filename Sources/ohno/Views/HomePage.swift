//
//  HomePage.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot

extension String: Component {
    public var body: any Plot.Component {
        ComponentGroup(html: self)
    }
}

struct HomePage: WebPage {
    var blog: Blog

    var page: Page {
        Page(title: blog.name) {
            H1(
                Link(url: "/") {
                    MarkdownText(blog.name)
                }
            )
            .class("subdue")

            Div {
                MarkdownText("---")
                for post in blog.posts() {
                    PostRow(post: post)
                    MarkdownText("---")
                }
            }.class("posts")
        } footer: {}
    }
}
