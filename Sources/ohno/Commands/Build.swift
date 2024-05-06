//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import ArgumentParser

public struct Build: AsyncParsableCommand {
	public init() { }
	public mutating func run() async throws {
		try await Blog.current().build()
	}
}
