import ArgumentParser

// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

@main
struct OhNo: AsyncParsableCommand {
	static let version = "ohno \(OhNoVersion)"

	static let configuration = CommandConfiguration(
		commandName: "ohno",
		abstract: "A lil blog generator",
		version: version,
		subcommands: [Build.self, Init.self, Serve.self, New.self, Edit.self]
	)
}
