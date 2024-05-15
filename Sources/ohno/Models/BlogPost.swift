//
//  BlogPost.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Ink
import LilHTML
import Splash
import TOMLKit
import Typographizer

extension Markdown {
	var excerpt: String {
		metadata["excerpt"] ?? {
			let parser = HTML(html: html)
			if let parsed = try? parser.parse().get(),
			   let firstParagraph = parsed.first(.p),
			   let content = firstParagraph.textContent.presence
			{
				return content
			} else {
				return ""
			}
		}()
	}
}

struct BlogPost: Codable, Hashable {
	enum Error: Swift.Error {
		case invalidFile(String)
	}

	let blog: Blog
	var title: String
	var excerpt: String
	var contents: String

	let slug: String
	let author: String?
	let publishedAt: Date
	let tags: [String]
	let prologue: String?

	var imageCode: String?

	static func from(url: URL, in blog: Blog) throws -> BlogPost {
		var imageCode = ""
		let parser = MarkdownParser(modifiers: [
			.init(target: .headings) { heading in
				if heading.html.contains("<h1>") {
					return ""
				} else {
					return heading.html
				}
			},
			.splashCodeBlocks(withFormat: HTMLOutputFormat()) { code in
				imageCode = code
			},
		])

		var postMarkdown = try String(contentsOf: url)

		postMarkdown.replace(#/--- SECTION/#) { _ in
			"""
			<hr class="section-break" />
			"""
		}

		// Hack around Ink not supporting footnotes
		postMarkdown.replace(#/\[\^(\d+)\]((?:[^:]|$))/#) { match in
			let number = match.output.1
			return """
			<sup><a id="footnote-link-\(number)" href="#footnote-\(number)">\(number)</a></sup>\(match.output.2)
			"""
		}
		postMarkdown.replace(#/\[\^(\d+)\]:(.*)/#) { match in
			let number = match.output.1
			let comment = MarkdownText(String(match.output.2), debug: true).html
			return """
			<div class="footnote" id="footnote-\(number)">
				<strong class="footnote-number">\(number).</strong>
				<p>\(comment) <a class="back" href="#footnote-link-\(number)">↩</a></p>
			</div>
			"""
		}

		let markdown = parser.parse(postMarkdown)

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
			author: markdown.metadata["author"] ?? blog.author ?? "",
			contents: markdown.html,
			publishedAt: publishedAt,
			tags: markdown.metadata["tags", default: ""].split(separator: #/,\s*/#).map(String.init),
			imageCode: imageCode,
			prologue: markdown.metadata["prologue"]
		)
	}

	init(
		blog: Blog,
		title: String,
		excerpt: String,
		slug: String,
		author: String,
		contents: String,
		publishedAt: Date,
		tags: [String],
		imageCode: String? = nil,
		prologue: String? = nil
	) {
		self.blog = blog
		self.title = title.typographized(language: Locale.current.language.minimalIdentifier, isHTML: true, ignore: ["`"])
		self.excerpt = excerpt.typographized(language: Locale.current.language.minimalIdentifier, isHTML: true, ignore: ["`"])
		self.slug = slug
		self.author = author
		self.contents = contents.typographized(language: Locale.current.language.minimalIdentifier, isHTML: true, ignore: ["`"])
		self.publishedAt = publishedAt
		self.tags = tags
		self.imageCode = imageCode
		self.prologue = prologue
	}

	var hasImage: Bool {
		guard let imageCode else {
			return false
		}

		return !imageCode.isBlank
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
			contents,
		].joined(separator: "\n")
	}
}
