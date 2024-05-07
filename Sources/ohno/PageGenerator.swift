//
//  PageGenerator.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Plot

struct PageGenerator {
	let blog: Blog
	let page: Page

	func html() async throws -> HTML {
		let customHead = try? String(contentsOf: blog.local.headHTML)
		let customStyles = try? String(contentsOf: blog.local.style)
		let customFooter = try? String(contentsOf: blog.local.footer)

		return HTML(
			.attribute(.attribute(named: "lang", value: blog.lang ?? Locale.current.language.minimalIdentifier)),
			.attribute(.attribute(named: "color-mode", value: "user")),
			.head(
				.meta(.content("text/html"), .charset(.utf8), .attribute(named: "http-equiv", value: "Content-Type")),
				.meta(.name("viewport"), .content("width=device-width, initial-scale=1.0")),
				.group(page.opengraph?.nodes ?? []),
				.title(page.title),
				.link(.rel(.stylesheet), .href("https://unpkg.com/mvp.css")),
				.style(customStyles ?? ""),
				.raw(customHead ?? "")
			),
			.body(
				.main(
					.class("container"),
					page.content.convertToNode(),
					.footer(
						page.footer.convertToNode(),
						MarkdownText(customFooter ?? "").convertToNode()
					)
				)
			)
		)
	}
}
