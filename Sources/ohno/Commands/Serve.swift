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
import Splash

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

// TODO: Should just build the site then serve out of that
public struct Serve: AsyncParsableCommand {
	@Option var path: String?

	public init() { }
	public mutating func run() async throws {
		let server = HTTPServer(port: 8080, logger: .print(category: "ohno"))
		let blog = try Blog.current(with: path)

		@Sendable func serve(_ webpage: any WebPage, blog: Blog) async throws -> HTTPResponse {
			try await ServerResponse(blog: blog, page: webpage.page).response()
		}

		await server.appendRoute("") { _ in
			return try await serve(HomePage(blog: blog), blog: blog)
		}

		await server.appendRoute("posts/*") { req in
			guard let slug = req.path.split(separator: "/").last else {
				print("not found")
				return try await ServerResponse(blog: blog, html: "Nope", status: .notFound).response()
			}

			let blogPost = try BlogPost.from(url: blog.local.posts.appending(path: slug + ".md"), in: blog)

			return try await serve(PostPage(post: blogPost), blog: blog)
		}

		await server.appendRoute("images/*") { req in
			guard let slug = req.path.split(separator: "/").last else {
				return try await ServerResponse(blog: blog, html: "Nope", status: .notFound).response()
			}

			let blogPost = try BlogPost.from(url: blog.local.posts.appending(path: slug + ".md"), in: blog)

			if let code = blogPost.imageCode,
				 let imageData = try ImageGenerator(code: code).generate(size: .init(width: 600, height: 400), colors: try CSS().themeColors(from: blog.local.style)) {
				var headers: [HTTPHeader: String] = [:]
				headers[HTTPHeader.contentType] = "image/png"
				return HTTPResponse(statusCode: .ok, headers: headers, body: imageData)
			} else {
				return try await ServerResponse(blog: blog, html: "Could not generate image.", status: .notFound).response()
			}
		}

		await server.appendRoute("tag/*") { req in
			guard let tag = req.path.split(separator: "/").last else {
				return try await ServerResponse(blog: blog, html: "Nope", status: .notFound).response()
			}

			let posts = blog.posts().filter { $0.tags.contains(String(tag)) }
			return try await serve(TagPage(blog: blog, tag: String(tag), posts: posts), blog: blog)
		}

		await server.appendRoute("feed.xml") { req in
			return try await ServerResponse(blog: blog, html: RSSPage(blog, posts: blog.posts()).body.render()).response(contentType: "application/rss+xml")
		}

		try await server.start()
	}


}
