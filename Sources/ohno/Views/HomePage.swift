//
//  HomePage.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Plot

extension String: Component {
	public var body: any Plot.Component {
		ComponentGroup(html: self)
	}
}

struct HomePage {
	var blog: Blog

	func page() -> Page {
		Page(title: blog.name) {
			H1(
				Link(blog.name, url: "/")
			)
			.class("subdue")

			Div {
				H5("Blog Posts")
					.class("posts-header-label")
				for post in blog.posts() {
					post.row()
				}
			}.class("posts")
		} footer: {
		}
	}
}
