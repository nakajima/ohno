//
//  Page.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot

extension Never: Component {
	public var body: any Plot.Component {
		EmptyComponent()
	}
}

protocol WebPage {
	associatedtype Content: Component
	associatedtype Footer: Component

	var title: String { get }
	var opengraph: OpenGraph? { get }
	@ComponentBuilder func content() -> Content
	@ComponentBuilder func head() -> [Node<HTML.HeadContext>]
	@ComponentBuilder func footer() -> Footer?
}

// Default conformances
extension WebPage {
	var opengraph: OpenGraph? { nil }

	func head() -> [Node<HTML.HeadContext>] {
		[]
	}

	func content() -> some Component {
		Text("")
	}

	func footer() -> Never? {
		nil
	}
}

// Render
extension WebPage {
	func render(in blog: Blog, indentedBy indentationKind: Indentation.Kind? = nil) async throws -> String {
		try await PageGenerator(blog: blog, page: self).html().render(indentedBy: indentationKind)
	}
}

//
// struct Page<Content: Component, Footer: Component, Header: Component> {
//	var title: String
//	var content: Content
//	var footer: Footer?
//	var head: Header?
//	var opengraph: OpenGraph?
//
//	init(title: String, opengraph: OpenGraph? = nil, header: Header, content: Content, footer: Footer) {
//		self.title = title
//		self.content = content
//		self.footer = footer
//		self.opengraph = opengraph
//	}
//
//	init(
//		title: String,
//		opengraph: OpenGraph? = nil,
//		@ComponentBuilder content: () -> Content,
//		@ComponentBuilder footer: () -> Footer,
//		@ComponentBuilder head: () -> Header
//	) {
//		self.title = title
//		self.content = content()
//		self.footer = footer()
//		self.head = head()
//		self.opengraph = opengraph
//	}
// }
//
// extension Page where Header == Never, Footer == Never {
//	init(
//		title: String,
//		opengraph: OpenGraph? = nil,
//		@ComponentBuilder content: () -> Content
//	) {
//		self.title = title
//		self.content = content()
//		self.opengraph = opengraph
//	}
// }
//
// extension Page where Header == Never {
//	init(
//		title: String,
//		opengraph: OpenGraph? = nil,
//		@ComponentBuilder content: () -> Content,
//		@ComponentBuilder footer: () -> Footer
//	) {
//		self.title = title
//		self.content = content()
//		self.footer = footer()
//		self.opengraph = opengraph
//	}
// }
//
//
// extension Page where Footer == Never {
//	init(
//		title: String,
//		opengraph: OpenGraph? = nil,
//		@ComponentBuilder content: () -> Content,
//		@ComponentBuilder head: () -> Header
//	) {
//		self.title = title
//		self.content = content()
//		self.head = head()
//		self.opengraph = opengraph
//	}
// }
