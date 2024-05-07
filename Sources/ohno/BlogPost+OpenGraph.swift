//
//  BlogPost+OpenGraph.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation

extension BlogPost {
	var opengraph: OpenGraph {
		OpenGraph(
			title: title,
			imageURL: hasImage ? blog.links.images.appending(path: "\(slug).png").absoluteString : nil,
			articleAuthor: author,
			url: permalink,
			description: excerpt,
			siteName: blog.name,
			publishedAt: publishedAt,
			tags: tags
		)
	}
}
