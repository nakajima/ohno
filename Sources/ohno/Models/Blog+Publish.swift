//
//  Blog+Publish.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Plot

extension Blog {
	func build(in destination: URL? = nil) async throws {
		let startTime = CFAbsoluteTimeGetCurrent()
		var builder = BlogBuilder(blog: self, destination: destination ?? local.build)
		try await builder.build()
		let endTime = CFAbsoluteTimeGetCurrent()
		print("Blog built in \(endTime - startTime) seconds.".green())
	}
}
