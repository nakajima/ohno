//
//  PostRow.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation
import Plot

struct PostRow: Component {
	var post: BlogPost

	var body: any Component {
		Article {
			H2 {
				Link(url: "/posts/\(post.slug)") {
					MarkdownText(post.title)
				}
			}

			if let excerpt = post.excerpt.presence {
				Paragraph {
					MarkdownText(excerpt)
				}
			}

			Time {
				Text(post.publishedAt.formatted(date: .abbreviated, time: .omitted))
			}
		}.class("post-row")
	}
}
