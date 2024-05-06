//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot

struct TagPage {
	let blog: Blog
	let tag: String
	let posts: [BlogPost]

	var body: Page {
		Page(title: "Posts tagged “\(tag)”") {
			Header {
				H2 {
					Link(blog.name, url: "/")
				}
				
				H1(
					Link("Posts tagged “\(tag)”", url: "/")
				)
				.class("subdue")
			}

			Div {
				for post in posts {
					post.row()
				}
			}.class("posts")
		} footer: {
		}
	}
}
