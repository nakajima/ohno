//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import TOMLKit
import Splash
import Ink
import LilParser

extension Markdown {
	var excerpt: String? {
		metadata["excerpt"] ?? {
			let parser = Parser(html: html)
			if let parsed = try? parser.parse().get(),
				 let firstParagraph = parsed.first(.p),
				 let content = firstParagraph.textContent.presence {
				return content
			} else {
				return nil
			}
		}()
	}
}

struct BlogPost: Codable, Hashable {
	enum Error: Swift.Error {
		case invalidFile(String)
	}

	let blog: Blog
	let title: String
	let excerpt: String?
	let slug: String
	let author: String?
	let contents: String
	let publishedAt: Date
	let tags: [String]

	static func from(url: URL, in blog: Blog) throws -> BlogPost {
		let parser = MarkdownParser(modifiers: [
			.init(target: .headings) { heading in
				if heading.html.contains("<h1>") {
					return ""
				} else {
					return heading.html
				}
			},
			.splashCodeBlocks(withFormat: HTMLOutputFormat())
		])


		let markdown = try parser.parse(String(contentsOf: url))

		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MM/dd/yyyy"

		guard let publishedAt = dateFormatter.date(from: markdown.metadata["publishedAt", default: ""]) else {
			throw Error.invalidFile("Invalid date")
		}

		return BlogPost(
			blog: blog,
			title: markdown.title ?? markdown.metadata["title"] ?? url.lastPathComponent,
			excerpt: markdown.excerpt,
			slug: url.deletingPathExtension().lastPathComponent,
			author: markdown.metadata["author"],
			contents: markdown.html,
			publishedAt: publishedAt,
			tags: markdown.metadata["tags", default: ""].split(separator: #/,\s*/#).map(String.init)
		)
	}

	var permalink: String {
		guard let url = blog.url, let url = URL(string: url) else {
			return "/" + slug
		}

		return url.appending(path: "posts/\(slug)").absoluteString
	}

	func toText() throws -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MM/dd/yyyy"

		return [
			"---",
			"title: \(title)",
			"author: \(author ?? "")",
			"publishedAt: \(dateFormatter.string(from: publishedAt))",
			"excerpt:",
			"tags: \(tags.joined(separator: ", "))",
			"---",
			contents
		].joined(separator: "\n")
	}
}
