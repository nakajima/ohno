//
//  Edit.swift
//
//
//  Created by Pat Nakajima on 5/15/24.
//

import ArgumentParser
import Foundation

public struct Edit: ParsableCommand {
	enum Error: Swift.Error, CustomStringConvertible {
		case noPostFound(String)

		var description: String {
			switch self {
			case let .noPostFound(name):
				"Could not find a post for \(name)"
			}
		}
	}

	@Argument(help: "Which post do you want to edit? Just a number will do (or the full post name)")
	public var name: String = ""

	@Option(help: "Where the blog lives if you're not currently in that directory") var path: String?

	public init() {}
	public func run() throws {
		let blog = try Blog.current(with: path)

		guard let post = blog.posts().first(where: { $0.slug.lowercased().starts(with: name.lowercased()) }) else {
			throw Error.noPostFound(name)
		}

		let editor = ProcessInfo.processInfo.environment["MARKDOWN_EDITOR"] ?? ProcessInfo.processInfo.environment["EDITOR"] ?? "vi"
		try Process.run(URL(string: "file:///usr/bin/open")!, arguments: [
			blog.local.posts.appending(path: post.slug + ".md").absoluteString,
			"-a",
			editor,
		])
	}
}
