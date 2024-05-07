//
//  OpenGraph.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot

struct OpenGraph {
	let title: String
	let imageURL: String?
	let articleAuthor: String?
	let url: String
	let description: String?
	let siteName: String
	let publishedAt: Date?
	let tags: [String]

	var nodes: [Node<HTML.HeadContext>] {
		var nodes: [Node<HTML.HeadContext>] = [
			.meta(.property("og:title"), .content(title)),
			.meta(.property("og:type"), .content("website")),
			.meta(.property("og:url"), .content(url)),
			.meta(.property("og:site_name"), .content(siteName)),
		]

		if let imageURL {
			nodes.append(.meta(.property("og:image"), .content(imageURL)))
		}

		if let description {
			nodes.append(.meta(.property("og:description"), .content(description)))
		}

		if let articleAuthor {
			nodes.append(.meta(.property("article:author"), .content(articleAuthor)))
		}

		if !tags.isEmpty {
			nodes.append(.meta(.name("keywords"), .content(tags.joined(separator: ", "))))
		}

		if let publishedAt {
			nodes.append(.meta(.property("article:published_time"), .content(publishedAt.formatted(.iso8601))))
		}

		return nodes
	}
}
