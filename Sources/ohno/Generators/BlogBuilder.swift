//
//  BlogBuilder.swift
//
//
//  Created by Pat Nakajima on 5/8/24.
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

	func rebuild(file: String) async throws {
		guard let filename = URL(string: file)?.lastPathComponent else {
			print("Unknown filename change: \(file)".yellow())
			return
		}

		switch filename {
		case "style.css":
			print("Rebuilding CSS".green())
			try buildCSS()
		case _ where filename.hasSuffix(".md"):
			if let post = blog.posts().first(where: { $0.filename == filename }) {
				print("Rebuilding post: \(filename)".green())
				try await buildPost(post: post)
				try await buildTags()
				try await buildHome()
				try await buildRSS()
			} else {
				fallthrough
			}
		case _ where file.contains("/public/"):
			print("Syncing public".green())
			try buildPublic()
		case _ where filename.hasSuffix("codenotes.js.swift"):
			print("Building codenotes.js".green())
			try buildCodeNotesJS()
		default:
			print("Unhandled file change: \(filename)".yellow())
		}
	}

	func buildCSS() throws {
		if let customCSS = try? String(contentsOf: blog.local.style) {
			let minified = CSSMinifier.minify(css: customCSS)
			try write(minified, to: "style.css")
		}
	}

	func buildPost(post: BlogPost) async throws {
		try write(post.toText(), to: "posts/\(post.slug).md")
		try await write(PostPage(post: post).render(in: blog), to: "posts/\(post.slug)/index.html")

		if let code = post.imageCode, let imageData = try await CodeImageGenerator(code: code).generate(colors: CSS().themeColors(from: blog.local.style)) {
			try write(imageData, to: "images/\(post.slug).png")
		}

		try await buildHome()
	}

	func buildHome() async throws {
		let home = try await HomePage(blog: blog).render(in: blog).render()
		try write(home, to: "index.html")
	}

	func buildRSS(posts: [BlogPost]? = nil) async throws {
		let feed = RSSPage(blog, posts: posts ?? blog.posts()).body.render()
		try write(feed, to: "feed.xml")
	}

	func buildPublic() throws {
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

	func buildTags(posts: [BlogPost]? = nil, trackBuilt _: Bool = false) async throws {
		let postsByTag: [String: [BlogPost]] = (posts ?? blog.posts()).reduce(into: [:]) { result, post in
			for tag in post.tags {
				result[tag, default: []].append(post)
			}
		}

		for (tag, posts) in postsByTag {
			let html = try await TagPage(blog: blog, tag: tag, posts: posts).render(in: blog)
			try write(html, to: "tag/\(tag)/index.html")
		}
	}

	mutating func buildTags(posts: [BlogPost]? = nil) async throws {
		let postsByTag: [String: [BlogPost]] = (posts ?? blog.posts()).reduce(into: [:]) { result, post in
			for tag in post.tags {
				result[tag, default: []].append(post)
			}
		}

		for (tag, posts) in postsByTag {
			let html = try await TagPage(blog: blog, tag: tag, posts: posts).render(in: blog)
			try write(html, to: "tag/\(tag)/index.html")
			built(url: blog.links.tag(tag).absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 0.3)
		}
	}

	func buildSiteMap() throws {
		let siteMap = SiteMapPage(urls: builtPages)
		try write(siteMap.body, to: "sitemap.xml")
		try write(Robots(blog: blog).body, to: "robots.txt")
	}

	func buildCodeNotesJS() throws {
		let codenotesURL = destination.appending(path: "_codenotes.js")
		try? FileManager.default.removeItem(at: codenotesURL)
		try write(codeNotesJS, to: "_codenotes.js")
	}

	mutating func built(url: String, updatedAt: Date, changeFrequency: SiteMapChangeFrequency, priority: Double) {
		builtPages.append(.init(url: url, updatedAt: updatedAt, changeFrequency: changeFrequency, priority: priority))
	}

	mutating func build() async throws {
		let posts = blog.posts()

		for post in posts {
			try await buildPost(post: post)
			built(url: post.permalink, updatedAt: post.publishedAt, changeFrequency: .monthly, priority: 0.7)
		}

		try await buildTags(posts: posts, trackBuilt: true)

		try await buildHome()
		built(url: blog.links.home.absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 1)

		try buildCSS()

		try await buildRSS()
		built(url: blog.links.feed.absoluteString, updatedAt: posts.first?.publishedAt ?? Date(), changeFrequency: .weekly, priority: 0.2)

		// Only gets built when we build the full site
		try buildSiteMap()

		try buildPublic()
		try buildCodeNotesJS()
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
