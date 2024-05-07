//
//  PageGenerator.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Plot

struct HeadGenerator<Page: WebPage> {
	var blog: Blog
	var page: Page

	init(blog: Blog, page: Page) {
		self.blog = blog
		self.page = page
	}

	var head: [Node<HTML.HeadContext>] {
		var nodes: [Node<HTML.HeadContext>] = [
			.meta(.content("text/html"), .charset(.utf8), .attribute(named: "http-equiv", value: "Content-Type")),
			.meta(.name("viewport"), .content("width=device-width, initial-scale=1.0")),
			.group(page.opengraph?.nodes ?? []),
			.title(page.title),
		]

		if FileManager.default.fileExists(atPath: blog.local.public.appending(path: "favicon.png").path) {
			nodes.append(.link(.rel(.icon), .href("/favicon.png")))
		}

		if FileManager.default.fileExists(atPath: blog.local.style.path()) {
			nodes.append(.link(.rel(.stylesheet), .href("/style.css")))
		}

		if let customHead = try? String(contentsOf: blog.local.headHTML) {
			nodes.append(.raw(customHead))
		}

		return nodes
	}
}

struct PageGenerator<Page: WebPage> {
	let blog: Blog
	let page: Page

	func html() async throws -> HTML {
		let customFooter = try? String(contentsOf: blog.local.footer)
		let head = HeadGenerator(blog: blog, page: page)

		return HTML(
			.attribute(.attribute(named: "lang", value: blog.lang ?? Locale.current.language.minimalIdentifier)),
			.attribute(.attribute(named: "color-mode", value: "user")),
			.head(.group(head.head)),
			.body(
				.main(
					.class("container"),
					page.content().convertToNode(),
					.footer(
						page.footer().convertToNode(),
						MarkdownText(customFooter ?? "").convertToNode()
					)
				)
			)
		)
	}
}
