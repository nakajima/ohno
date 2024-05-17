// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ohno",
	platforms: [.macOS(.v14), .iOS(.v17)],
	products: [
		.executable(
			name: "ohno",
			targets: ["ohno"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
		.package(url: "https://github.com/LebJe/TOMLKit", from: "0.6.0"),
		.package(url: "https://github.com/JohnSundell/Plot", branch: "master"),
		.package(url: "https://github.com/JohnSundell/Ink", branch: "master"),
		.package(url: "https://github.com/JohnSundell/Splash", branch: "master"),
		.package(url: "https://github.com/swhitty/FlyingFox", branch: "main"),
		.package(url: "https://github.com/nakajima/LilHTML.swift", branch: "main"),
		.package(url: "https://github.com/nakajima/Typographizer", branch: "main"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.executableTarget(
			name: "ohno",
			dependencies: [
				"TOMLKit",
				"Plot",
				"FlyingFox",
				"Ink",
				"Splash",
				"Typographizer",
				.product(name: "LilHTML", package: "LilHTML.swift"),
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
		.testTarget(
			name: "ohnoTests",
			dependencies: ["ohno"]
		),
	]
)
