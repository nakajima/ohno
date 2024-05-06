//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/4/24.
//

import FlyingFox
import Foundation
import ArgumentParser
import Plot

struct ServerResponse {
	var html: String?
	var blog: Blog
	var status: HTTPStatusCode
	var page: Page

	init(blog: Blog, page: Page, status: HTTPStatusCode = .ok) {
		self.blog = blog
		self.status = status
		self.page = page
	}

	init(blog: Blog, html: String, status: HTTPStatusCode = .ok) {
		self.html = html
		self.status = status
		self.blog = blog
		self.page = .init()
	}

	public func response(contentType: String = "text/html") async throws -> HTTPResponse {
		var headers: [HTTPHeader: String] = [:]
		headers[HTTPHeader.contentType] = contentType
		headers[HTTPHeader.contentEncoding] = "utf-8"

		if let html {
			return HTTPResponse(statusCode: status, headers: headers, body: Data(html.utf8))
		} else {
			let html = try await PageGenerator(blog: blog, page: page).html().render(indentedBy: .spaces(2))
			return HTTPResponse(statusCode: status, headers: headers, body: Data(html.utf8))
		}
	}
}

public struct Serve: AsyncParsableCommand {
	@Option var path: String?

	public init() { }
	public mutating func run() async throws {
		let server = HTTPServer(port: 8080, logger: .print(category: "ohno"))
		let blog = try Blog.current(with: path)

		await server.appendRoute("") { _ in
			print("serving /")
			return try await ServerResponse(blog: blog, page: HomePage(blog: blog).page()).response()
		}

		await server.appendRoute("posts/*") { req in
			guard let slug = req.path.split(separator: "/").last else {
				print("not found")
				return try await ServerResponse(blog: blog, html: "Nope", status: .notFound).response()
			}

			let blogPost = try BlogPost.from(url: blog.local.posts.appending(path: slug + ".md"), in: blog)

			print("serving /posts/\(blogPost.slug).md")
			return try await ServerResponse(blog: blog, page: blogPost.page()).response()
		}

		await server.appendRoute("tag/*") { req in
			guard let tag = req.path.split(separator: "/").last else {
				return try await ServerResponse(blog: blog, html: "Nope", status: .notFound).response()
			}

			let posts = blog.posts().filter { $0.tags.contains(String(tag)) }
			let page = TagPage(blog: blog, tag: String(tag), posts: posts)

			print("serving /tag/\(tag)")

			return try await ServerResponse(blog: blog, page: page.body).response()
		}

		await server.appendRoute("feed.xml") { req in
			return try await ServerResponse(blog: blog, html: RSSPage(blog, posts: blog.posts()).body.render()).response(contentType: "application/rss+xml")
		}

		try await server.start()
	}
}
