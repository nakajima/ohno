//
//  CSS.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation
import Splash

// This is a hack but i didn't want to pull in an actual css parser
struct CSS {
    let color = #/\.(keyword|type|call|string|number|comment|property|dotAccess|preprocessing)\s+\{\s*\n\s*color:\s*#([a-f0-9]{6,8})/#.ignoresCase()

    func themeColors(from url: URL) throws -> [TokenType: HexColor] {
        let css = try String(contentsOf: url)
        let matches = css.matches(of: color)
        return matches.reduce(into: [:]) { result, match in
            let token = match.output.1
            let color = match.output.2

            let tokenType: TokenType? = switch token {
            case "keyword": .keyword
            case "type": .type
            case "call": .call
            case "string": .string
            case "number": .number
            case "comment": .comment
            case "property": .property
            case "dotAccess": .dotAccess
            case "preprocessing": .preprocessing
            default:
                nil
            }

            if let tokenType {
                result[tokenType] = HexColor(color)
            }
        }
    }
}
