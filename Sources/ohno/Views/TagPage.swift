//
//  TagPage.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot

struct TagPage: WebPage {
	let blog: Blog
	let tag: String
	let posts: [BlogPost]

	var title: String { "Tag: “\(tag)”" }

	func content() -> some Component {
		Header {
			H2 {
				Link(url: "/") {
					MarkdownText(blog.name)
				}
			}
			.class("site-name")

			H1(
				Link(url: "/") {
					Span("Tag: ").class("subdue")
					Text("“\(tag)”")
				}
			)
		}

		MarkdownText("---")
		Div {
			for post in posts {
				PostRow(post: post)
				MarkdownText("---")
			}

		}.class("posts")
	}
}
