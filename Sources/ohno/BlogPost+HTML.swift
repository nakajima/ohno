//
//  File.swift
//  
//
//  Created by Pat Nakajima on 5/4/24.
//

import Foundation
import Splash
import Plot

extension BlogPost {
	var opengraph: OpenGraph {
		OpenGraph(
			title: title,
			articleAuthor: author,
			url: permalink,
			description: excerpt,
			siteName: blog.name,
			publishedAt: publishedAt,
			tags: tags
		)
	}

	func row() -> any Component {
		Article {
			H2 {
				Link(url: "/posts/\(slug)") {
					MarkdownText(title)
				}
			}

			if let excerpt {
				Paragraph {
					MarkdownText(excerpt)
				}
			}

			Time {
				Text(publishedAt.formatted(date: .abbreviated, time: .omitted))
			}
		}.class("post-row")
	}

	func page() -> Page {
		Page(title: title, opengraph: opengraph) {
			H2 {
				Link(blog.name, url: "/")
			}

			Article {
				H1 {
					MarkdownText(title)
				}
				
				ComponentGroup(html: MarkdownDecorator().decorate(contents))
			}
		} footer: {
			Paragraph {
				Text("Posted")

				Time(datetime: publishedAt.formatted(.iso8601)) {
					Text(publishedAt.formatted(date: .abbreviated, time: .omitted))
				}

				if !tags.isEmpty {
					Text(" in ")
					for tag in tags {
						Link(tag, url: "/tag/\(tag)")
							.class("tag")
					}
				}
			}
		}
	}
}
