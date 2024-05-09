//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/8/24.
//

import Plot
import Foundation

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
			try await write(PostPage(post: post).render(in: blog), to: "posts/\(post.slug)/index.html")
			built(url: post.permalink, updatedAt: post.publishedAt, changeFrequency: .monthly, priority: 0.7)

			if let code = post.imageCode, let imageData = try await CodeImageGenerator(code: code).generate(colors: CSS().themeColors(from: blog.local.style)) {
				try write(imageData, to: "images/\(post.slug).png")
			}
		}

		let postsByTag: [String: [BlogPost]] = posts.reduce(into: [:]) { result, post in
			for tag in post.tags {
				result[tag, default: []].append(post)
			}
		}

		for (tag, posts) in postsByTag {
			let html = try await TagPage(blog: blog, tag: tag, posts: posts).render(in: blog)
			try write(html, to: "tag/\(tag)/index.html")
			built(url: blog.links.tag(tag).absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 0.3)
		}

		let home = try await HomePage(blog: blog).render(in: blog).render()
		try write(home, to: "index.html")
		built(url: blog.links.home.absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 1)

		let feed = RSSPage(blog, posts: posts).body.render()
		try write(feed, to: "feed.xml")
		built(url: blog.links.feed.absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 0.2)

		let siteMap = SiteMapPage(urls: builtPages)
		try write(siteMap.body, to: "sitemap.xml")
		try write(Robots(blog: blog).body, to: "robots.txt")

		if let customCSS = try? String(contentsOf: blog.local.style) {
			try write(customCSS, to: "style.css")
		}

		if FileManager.default.fileExists(atPath: blog.local.public.path) {
			for item in try FileManager.default.contentsOfDirectory(atPath: blog.local.public.path) {
				if item == ".DS_Store" { continue }

				let publicFile = blog.local.public.appending(path: item)
				do {
					try FileManager.default.copyItem(at: publicFile, to: destination.appending(path: item))
				} catch {
					print("\(error.localizedDescription)".yellow().dim())
				}
			}
		}
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
