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

	var title: String { get }
	var opengraph: OpenGraph? { get }
	@ComponentBuilder func content() -> Content
	@ComponentBuilder func head() -> [Node<HTML.HeadContext>]
	@ComponentBuilder func footer() -> ComponentGroup?
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

	func footer() -> ComponentGroup? {
		nil
	}
}

// Render
extension WebPage {
	func render(in blog: Blog, indentedBy indentationKind: Indentation.Kind? = .none) async throws -> String {
		try await PageGenerator(blog: blog, page: self).html().render(indentedBy: indentationKind)
	}
}
