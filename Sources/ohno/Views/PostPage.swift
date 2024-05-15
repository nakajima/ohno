//
//  PostPage.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation
import Plot
import Splash

struct PostPage: WebPage {
	var post: BlogPost

	var title: String {
		post.title
	}

	var opengraph: OpenGraph? {
		post.opengraph
	}

	@ComponentBuilder func content() -> some Component {
		H2 {
			Link(url: "/") {
				MarkdownText(post.blog.name)
			}
		}
		.class("site-name")

		Article {
			H1 {
				MarkdownText(post.title)
			}

			if let prologue = post.prologue {
				ComponentGroup {
					Node.small(MarkdownText(prologue).convertToNode(), .class("prologue"))
				}
			}

			ComponentGroup(html: MarkdownDecorator().decorate(post.contents))
		}
		.class("post-body")
	}

	@ComponentBuilder func footer() -> ComponentGroup? {
		Paragraph {
			MarkdownText("---")

			Text("Posted ")

			Time(datetime: post.publishedAt.formatted(.iso8601)) {
				Text(post.publishedAt.formatted(date: .abbreviated, time: .omitted))
			}

			if !post.tags.isEmpty {
				Text(" in ")
				for tag in post.tags {
					Link(tag, url: "/tag/\(tag.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)")
						.class("tag")
				}
			}
		}
	}
}
