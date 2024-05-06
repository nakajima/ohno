//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import TOMLKit
import ArgumentParser

public struct Init: ParsableCommand {
	enum InitError: Error {
		case fileExists, invalidURL
	}

	@Argument(help: "The name of the blog")
	var name: String

	public init() { }
	public func run() throws {
		let destination = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appending(path: name)

		if FileManager.default.fileExists(atPath: destination.path) {
			throw InitError.fileExists
		}

		let name = ask("What do you want to call your blog? \("(You can edit this later obviously.)".dim())")
		let author = ask("What’s your name? \("Posts will automatically have the author set to this.".dim())")
		let about = ask("Wanna add a description? \("Press Enter to skip.".dim())")
		let url = ask("What URL will your blog be at?")
		let lang = Locale.current.language.languageCode?.identifier

		let blog = Blog(location: destination, name: name, about: about, author: author, url: url, lang: lang)
		let encoded = try TOMLEncoder().encode(blog) + "\n"
		
		try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
		try encoded.write(to: blog.configurationURL, atomically: true, encoding: .utf8)

		print("Heck yea, made your blog.".cyan().bold())
		print("cd \(destination.lastPathComponent)".bold() + " to get started.")
	}

	private func ask(_ string: String) -> String {
		print(string)
		return readLine() ?? ""
	}
}
