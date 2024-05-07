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

	var title: String { blog.name }

	var opengraph: OpenGraph? {
		var imageURL: String?
		if FileManager.default.fileExists(atPath: blog.local.public.appending(path: "site.png").path) {
			imageURL = "/site.png"
		}

		return .init(
			title: blog.name,
			imageURL: imageURL,
			articleAuthor: blog.author,
			url: blog.url ?? "https://example.com",
			description: blog.about,
			siteName: blog.name,
			publishedAt: blog.posts().first?.publishedAt,
			tags: []
		)
	}

	func content() -> some Component {
		Div {
			H1(
				Link(url: "/") {
					MarkdownText(blog.name)
				}
			)

			Div {
				MarkdownText("---")
				for post in blog.posts() {
					PostRow(post: post)
					MarkdownText("---")
				}
			}.class("posts")
		}
	}
}
