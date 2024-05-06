//
//  New.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import ArgumentParser
import Foundation

public struct New: ParsableCommand {
    @Argument(help: "What should the new post be called")
    public var title: String = "A brand new blog post"

    public init() {}
    public func run() throws {
        let blog = try Blog.current()
        let newPost = BlogPost(
            blog: blog,
            title: title,
            excerpt: "",
            slug: title.slugified(),
            author: blog.author ?? "who am i",
            contents: "Here's a new post.",
            publishedAt: Date(),
            tags: []
        )

        try blog.save(newPost, filename: title.slugified() + ".md")
    }
}
