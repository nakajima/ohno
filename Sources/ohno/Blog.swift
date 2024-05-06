//
//  Blog.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import TOMLKit

struct Blog: Codable, Hashable {
	enum Error: Swift.Error, CustomStringConvertible {
		case notInBlog
		case invalidConfiguration

		var description: String {
			return switch self {
			case .notInBlog:
				"Looks like you're not in an ohno blog directory.".red()
			case .invalidConfiguration:
				"Your ohno.toml file looks messed up."
			}
		}
	}

	// Where the blog lives on disk
	var location: URL

	// Attributes
	let name: String
	let about: String?
	let author: String?
	let url: String?
	let lang: String?

	enum CodingKeys: CodingKey {
		case name, about, author, url, lang
	}

	init(location: URL, name: String, about: String?, author: String?, url: String?, lang: String?) {
		self.location = location
		self.name = name
		self.about = about
		self.author = author
		self.url = url
		self.lang = lang
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		name = try container.decode(String.self, forKey: .name)
		about = try container.decodeIfPresent(String.self, forKey: .about)
		author = try container.decodeIfPresent(String.self, forKey: .author)
		url = try container.decodeIfPresent(String.self, forKey: .url)
		lang = try container.decodeIfPresent(String.self, forKey: .lang)
		location = URL(filePath: FileManager.default.currentDirectoryPath)
	}

	var configurationURL: URL {
		location.appending(path: "ohno.toml")
	}

	var postsURL: URL {
		location.appending(path: "posts", directoryHint: .isDirectory)
	}

	var publishURL: URL {
		location.appending(path: "publish", directoryHint: .isDirectory)
	}

	var styleURL: URL {
		location.appending(path: "style.css")
	}

	var footerURL: URL {
		location.appending(path: "footer.html")
	}

	static func current(with path: String? = nil) throws -> Blog {
		let url = if let path {
			URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appending(path: path)
		} else {
			URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
		}

		let toml: String
		do {
			toml = try String(contentsOf: url.appending(path: "ohno.toml"))
		} catch {
			throw Error.notInBlog
		}

		var blog: Blog
		do {
			blog = try TOMLDecoder().decode(Blog.self, from: toml)
		} catch {
			throw Error.invalidConfiguration
		}

		blog.location = url

		return blog
	}

	func save(_ blogPost: BlogPost, filename: String) throws {
		try? FileManager.default.createDirectory(at: postsURL, withIntermediateDirectories: true)
		let fileContents = try blogPost.toText()
		let destination = postsURL.appending(path: "\(posts().count)-\(filename)")
		try fileContents.write(to: destination, atomically: true, encoding: .utf8)
	}

	func posts() -> [BlogPost] {
		guard FileManager.default.fileExists(atPath: postsURL.path) else {
			return []
		}

		do {
			let postFiles = try FileManager.default.contentsOfDirectory(at: postsURL, includingPropertiesForKeys: [.nameKey]).filter { $0.pathExtension == "md" }
			return postFiles.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).map {
				try! BlogPost.from(url: $0, in: self)
			}
		} catch {
			return []
		}
	}
}
