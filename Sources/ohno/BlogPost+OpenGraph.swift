//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation

extension BlogPost {
	var opengraph: OpenGraph {
		OpenGraph(
			title: title,
			articleAuthor: author,
			url: permalink,
			description: excerpt,
			siteName: blog.name,
			publishedAt: publishedAt,
			tags: tags
		)
	}
}
