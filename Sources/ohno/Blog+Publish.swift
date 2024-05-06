//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Plot

extension Blog {
	func build() async throws {
		let posts = posts()

		for post in posts {
			try write(post.toText(), to: "posts/\(post.slug).md")
			try await write(PageGenerator(blog: self, page: post.page()).html().render(), to: "posts/\(post.slug)/index.html")
		}

		let postsByTag: [String: [BlogPost]] = posts.reduce(into: [:]) { result, post in
			for tag in post.tags {
				result[tag, default: []].append(post)
			}
		}

		for (tag, posts) in postsByTag {
			let page = TagPage(blog: self, tag: tag, posts: posts).body
			let html = try await PageGenerator(blog: self, page: page).html().render()
			try write(html, to: "tag/\(tag)/index.html")
		}

		let home = try await PageGenerator(blog: self, page: HomePage(blog: self).page()).html().render()
		try write(home, to: "index.html")

		let feed = RSSPage(self, posts: posts).body.render()
		try write(feed, to: "feed.xml")
	}

	private func write(_ contents: String, to path: String) throws {
		try? FileManager.default.createDirectory(at: local.build.appending(path: path).deletingLastPathComponent(), withIntermediateDirectories: true)
		try contents.write(to: local.build.appending(path: path), atomically: true, encoding: .utf8)
	}
}
