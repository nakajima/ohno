//
//  Serve.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import ArgumentParser
import FlyingFox
import Foundation
import Plot
import Splash

public struct Serve: AsyncParsableCommand {
    @Option var path: String?

    public init() {}
    public mutating func run() async throws {
        let server = HTTPServer(port: 8080, logger: .print(category: "ohno"))
        let blog = try Blog.current(with: path)

        await server.appendRoute("*") { req in
            try await blog.build(in: blog.local.serve)

            var headers: [HTTPHeader: String] = [:]
            headers[HTTPHeader.contentType] = makeContentType(String(req.path.split(separator: "/").last ?? ""))

            let requestedURL = req.path == "/" ? blog.local.serve : blog.local.serve.appending(path: req.path)
            let fileURL: URL? = if FileManager.default.fileExists(atPath: requestedURL.path), !requestedURL.isDirectory {
                requestedURL
            } else if FileManager.default.fileExists(atPath: requestedURL.appending(path: "index.html").path) {
                requestedURL.appending(path: "index.html")
            } else {
                nil
            }

            print(fileURL)
            if let fileURL {
                return try .init(statusCode: .ok, headers: headers, body: Data(contentsOf: fileURL))
            } else {
                return .init(statusCode: .notFound)
            }
        }

        @Sendable func makeContentType(_ filename: String) -> String {
            let pathExtension = (filename.lowercased() as NSString).pathExtension
            switch pathExtension {
            case "json":
                return "application/json"
            case "html", "htm", "":
                return "text/html"
            case "css":
                return "text/css"
            case "js", "javascript":
                return "application/javascript"
            case "png":
                return "image/png"
            case "jpeg", "jpg":
                return "image/jpeg"
            case "pdf":
                return "application/pdf"
            case "svg":
                return "image/svg+xml"
            case "ico":
                return "image/x-icon"
            case "webp":
                return "image/webp"
            case "jp2":
                return "image/jp2"
            default:
                return "application/octet-stream"
            }
        }
//
        //		@Sendable func serve(_ webpage: any WebPage, blog: Blog) async throws -> HTTPResponse {
        //			try await ServerResponse(blog: blog, page: webpage.page).response()
        //		}
//
        //		await server.appendRoute("") { _ in
        //			return try await serve(HomePage(blog: blog), blog: blog)
        //		}
//
        //		await server.appendRoute("posts/*") { req in
        //			guard let slug = req.path.split(separator: "/").last else {
        //				print("not found")
        //				return try await ServerResponse(blog: blog, html: "Nope", status: .notFound).response()
        //			}
//
        //			let blogPost = try BlogPost.from(url: blog.local.posts.appending(path: slug + ".md"), in: blog)
//
        //			return try await serve(PostPage(post: blogPost), blog: blog)
        //		}
//
        //		await server.appendRoute("images/*") { req in
        //			if !req.path.hasSuffix(".png") {
        //				return try await ServerResponse(blog: blog, html: "Not found", status: .notFound).response()
        //			}
//
        //			guard let filename = req.path.split(separator: "/").last else {
        //				return try await ServerResponse(blog: blog, html: "Nope", status: .notFound).response()
        //			}
//
        //			let slug = filename.replacing(#/\.png$/#, with: "")
        //			let blogPost = try BlogPost.from(url: blog.local.posts.appending(path: slug + ".md"), in: blog)
//
        //			if let code = blogPost.imageCode,
        //				 let imageData = try await ImageGenerator(code: code).generate(size: .init(width: 600, height: 400), colors: try CSS().themeColors(from: blog.local.style)) {
        //				var headers: [HTTPHeader: String] = [:]
        //				headers[HTTPHeader.contentType] = "image/png"
        //				return HTTPResponse(statusCode: .ok, headers: headers, body: imageData)
        //			} else {
        //				return try await ServerResponse(blog: blog, html: "Could not generate image.", status: .notFound).response()
        //			}
        //		}
//
        //		await server.appendRoute("tag/*") { req in
        //			guard let tag = req.path.split(separator: "/").last else {
        //				return try await ServerResponse(blog: blog, html: "Nope", status: .notFound).response()
        //			}
//
        //			let posts = blog.posts().filter { $0.tags.contains(String(tag)) }
        //			return try await serve(TagPage(blog: blog, tag: String(tag), posts: posts), blog: blog)
        //		}
//
        //		await server.appendRoute("feed.xml") { req in
        //			return try await ServerResponse(blog: blog, html: RSSPage(blog, posts: blog.posts()).body.render()).response(contentType: "application/rss+xml")
        //		}

        try await server.start()
    }
}
