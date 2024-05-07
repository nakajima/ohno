//
//  File 2.swift
//  
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation

struct Robots {
	var blog: Blog

	var body: String {
		return """
		User-agent: *
		Disallow:
		Sitemap: \(blog.links.sitemap)
		"""
	}
}
