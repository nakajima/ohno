//
//  File.swift
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
		let customStyles = try? String(contentsOf: blog.styleURL)
		let customFooter = try? String(contentsOf: blog.footerURL)

		return HTML(
			.attribute(.attribute(named: "lang", value: blog.lang ?? Locale.current.language.minimalIdentifier)),
			.attribute(.attribute(named: "color-mode", value: "user")),
			.head(
				.meta(.content("text/html"), .charset(.utf8), .attribute(named: "http-equiv", value: "Content-Type")),
				.meta(.name("viewport"), .content("width=device-width, initial-scale=1.0")),
				.group(page.opengraph?.nodes ?? []),
				.title(page.title),
				.link(.rel(.stylesheet), .href("https://unpkg.com/mvp.css")),
				.style(customStyles ?? "")
			),
			.body(
				.main(
					.class("container"),
					page.content.convertToNode(),
					.hr(),
					.footer(
						page.footer.convertToNode(),
						.raw(customFooter ?? "")
					)
				)
			)
		)
	}
}
