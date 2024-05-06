//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot

struct TagPage: WebPage {
	let blog: Blog
	let tag: String
	let posts: [BlogPost]

	var page: Page {
		Page(title: "Tag: “\(tag)”") {
			Header {
				H2 {
					Link(url: "/") {
						MarkdownText(blog.name)
					}
				}
				.class("site-name")

				H1(
					Link("Tag: “\(tag)”", url: "/")
				)
				.class("subdue")
			}

			Div {
				for post in posts {
					PostRow(post: post)
				}
			}.class("posts")
		} footer: {
		}
	}
}
