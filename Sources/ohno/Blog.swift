//
//  Blog.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import TOMLKit

struct Blog: Codable, Hashable {
	struct URLs {
		var baseURL: URL

		init(baseURL: URL? = nil) {
			self.baseURL = baseURL ?? URL(string: "https://example.com")!
		}

		var home: URL { baseURL }
		var feed: URL { baseURL.appending(path: "feed.xml") }
		var images: URL { baseURL.appending(path: "images") }
		var sitemap: URL { baseURL.appending(path: "sitemap.xml") }

		func tag(_ tag: String) -> URL {
			baseURL.appending(path: "tag/\(tag)")
		}
	}

	struct Local {
		var location: URL

		var configuration: URL {
			location.appending(path: "ohno.toml")
		}

		var posts: URL {
			location.appending(path: "posts", directoryHint: .isDirectory)
		}

		var build: URL {
			location.appending(path: "build", directoryHint: .isDirectory)
		}

		var style: URL {
			location.appending(path: "style.css")
		}

		var headHTML: URL {
			location.appending(path: "head.html")
		}

		var footer: URL {
			location.appending(path: "footer.md")
		}

		var serve: URL {
			location.appending(path: ".serve")
		}

		var `public`: URL {
			location.appending(path: "public")
		}
	}

	enum Error: Swift.Error, CustomStringConvertible {
		case notInBlog(String)
		case invalidConfiguration

		var description: String {
			return switch self {
			case let .notInBlog(msg):
				"Looks like you're not in an ohno blog directory.\nerr: \(msg)".red()
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
		self.lang = lang ?? Locale.current.language.minimalIdentifier
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.name = try container.decode(String.self, forKey: .name)
		self.about = try container.decodeIfPresent(String.self, forKey: .about)
		self.author = try container.decodeIfPresent(String.self, forKey: .author)
		self.url = try container.decodeIfPresent(String.self, forKey: .url)
		self.lang = try container.decodeIfPresent(String.self, forKey: .lang)
		self.location = URL(filePath: FileManager.default.currentDirectoryPath)
	}

	var links: URLs {
		URLs(baseURL: URL(string: url ?? ""))
	}

	var local: Local {
		Local(location: location)
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
			throw Error.notInBlog(error.localizedDescription)
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
		try? FileManager.default.createDirectory(at: local.posts, withIntermediateDirectories: true)
		let fileContents = try blogPost.toText()
		let destination = local.posts.appending(path: "\(posts().count)-\(filename)")
		try fileContents.write(to: destination, atomically: true, encoding: .utf8)
	}

	func posts() -> [BlogPost] {
		guard FileManager.default.fileExists(atPath: local.posts.path) else {
			return []
		}

		do {
			let postFiles = try FileManager.default.contentsOfDirectory(at: local.posts, includingPropertiesForKeys: [.nameKey]).filter { $0.pathExtension == "md" }
			return postFiles.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }).compactMap {
				do {
					let post = try BlogPost.from(url: $0, in: self)

					if post.publishedAt < Date() {
						return post
					}
				} catch {
					print("Error loading \($0.lastPathComponent): \(error)")
				}

				return nil
			}
		} catch {
			return []
		}
	}
}
