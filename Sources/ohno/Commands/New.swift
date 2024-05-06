//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import ArgumentParser

public struct New: ParsableCommand {
	@Argument(help: "What should the new post be called")
	public var title: String = "A brand new blog post"

	public init() { }
	public func run() throws {
		let blog = try Blog.current()
		let newPost = BlogPost(
			blog: blog,
			title: title,
			excerpt: nil,
			slug: title.slugified(),
			author: blog.author,
			contents: "Here's a new post.",
			publishedAt: Date(),
			tags: []
		)

		try blog.save(newPost, filename: title.slugified() + ".md")
	}
}
