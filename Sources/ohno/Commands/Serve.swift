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
		let builder = BlogBuilder(blog: blog, destination: blog.local.serve)

		let fileWatcher = FileWatcher([
			blog.location.path,
		], { change in
			if change.path.contains(".serve") {
				return
			}

			Task {
				if change.fileChange || change.fileCreated || change.fileModified {
					try await builder.rebuild(file: change.path)
				}
			}
		}, .main)

		fileWatcher.start()

		await server.appendRoute("*") { req in
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

		try await server.start()
	}
}
