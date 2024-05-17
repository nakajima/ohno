//
//  PostPage.swift
//
//
//  Created by Pat Nakajima on 5/6/24.
//

import Foundation
import Plot
import Splash

enum RenderingContext {
	case html, rss
}

struct PostPage: WebPage {
	var post: BlogPost

	var title: String {
		post.title
	}

	var opengraph: OpenGraph? {
		post.opengraph
	}

	func head() -> [Node<HTML.HeadContext>] {
		if post.html(context: .html).contains("code-note-button") {
			return [.script(.src("/_codenotes.js"))]
		} else {
			return []
		}
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

			ComponentGroup(html: MarkdownDecorator().decorate(post.html(context: .html)))
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
