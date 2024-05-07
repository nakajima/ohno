//
//  Blog+Publish.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Plot

struct BlogBuilder {
	let blog: Blog
	let destination: URL
	var builtPages: [SiteMapPage.SiteMapURL] = []

	init(blog: Blog, destination: URL) {
		self.blog = blog
		self.destination = destination
	}

	mutating func built(url: String, updatedAt: Date, changeFrequency: SiteMapChangeFrequency, priority: Double) {
		builtPages.append(.init(url: url, updatedAt: updatedAt, changeFrequency: changeFrequency, priority: priority))
	}

	mutating func build() async throws {
		let posts = blog.posts()

		for post in posts {
			try write(post.toText(), to: "posts/\(post.slug).md")
			try await write(PageGenerator(blog: blog, page: PostPage(post: post).page).html().render(), to: "posts/\(post.slug)/index.html")
			built(url: post.permalink, updatedAt: post.publishedAt, changeFrequency: .monthly, priority: 0.7)

			if let code = post.imageCode, let imageData = try await ImageGenerator(code: code).generate(colors: CSS().themeColors(from: blog.local.style)) {
				try write(imageData, to: "images/\(post.slug).png")
			}
		}

		let postsByTag: [String: [BlogPost]] = posts.reduce(into: [:]) { result, post in
			for tag in post.tags {
				result[tag, default: []].append(post)
			}
		}

		for (tag, posts) in postsByTag {
			let page = TagPage(blog: blog, tag: tag, posts: posts).page
			let html = try await PageGenerator(blog: blog, page: page).html().render()
			try write(html, to: "tag/\(tag)/index.html")
			built(url: blog.links.tag(tag).absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 0.3)
		}

		let home = try await PageGenerator(blog: blog, page: HomePage(blog: blog).page).html().render()
		try write(home, to: "index.html")
		built(url: blog.links.home.absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 1)

		let feed = RSSPage(blog, posts: posts).body.render()
		try write(feed, to: "feed.xml")
		built(url: blog.links.feed.absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 0.2)

		let siteMap = SiteMapPage(urls: builtPages)
		try write(siteMap.body, to: "sitemap.xml")

		try write(Robots(blog: blog).body, to: "robots.txt")
	}

	private func write(_ contents: Data, to path: String) throws {
		try? FileManager.default.createDirectory(at: destination.appending(path: path).deletingLastPathComponent(), withIntermediateDirectories: true)
		try contents.write(to: destination.appending(path: path))
	}

	private func write(_ contents: String, to path: String) throws {
		try? FileManager.default.createDirectory(at: destination.appending(path: path).deletingLastPathComponent(), withIntermediateDirectories: true)
		try contents.write(to: destination.appending(path: path), atomically: true, encoding: .utf8)
	}
}

extension Blog {
	func build(in destination: URL? = nil) async throws {
		let startTime = CFAbsoluteTimeGetCurrent()
		var builder = BlogBuilder(blog: self, destination: destination ?? local.build)
		try await builder.build()
		let endTime = CFAbsoluteTimeGetCurrent()
		print("Blog built in \(endTime - startTime) seconds.".green())
	}
}
