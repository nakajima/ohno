//
//  String+Slug.swift
//
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation

public extension String {
    func slugified(
        separator: String = "-",
        allowedCharacters: NSCharacterSet = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-")
    ) -> String {
        replacing(#/([a-z])([A-Z])/#) { "\($0.output.1)-\($0.output.2)" }
            .lowercased()
            .components(separatedBy: allowedCharacters.inverted)
            .filter { $0 != "" }
            .joined(separator: separator)
    }
}
