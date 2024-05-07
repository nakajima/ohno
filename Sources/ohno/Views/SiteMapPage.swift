//
//  SiteMapPage.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation
import Plot

struct SiteMapPage {
	struct SiteMapURL {
		var url: String
		var updatedAt: Date
		var changeFrequency: Plot.SiteMapChangeFrequency
		var priority: Double
	}

	var urls: [SiteMapURL]

	var body: String {
		SiteMap(.group(urlNodes)).render()
	}

	var urlNodes: [Node<SiteMap.URLSetContext>] {
		urls.map { url in
			.url(
				.loc(url.url),
				.lastmod(url.updatedAt),
				.changefreq(url.changeFrequency),
				.priority(url.priority)
			)
		}
	}
}
