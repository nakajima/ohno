//
//  RSSPage.swift
//
//
//  Created by Pat Nakajima on 5/5/24.
//

import Foundation
import Ink
import Plot
import Splash

struct RSSPage {
    var blog: Blog
    var posts: [BlogPost]

    init(_ blog: Blog, posts: [BlogPost]) {
        self.blog = blog
        self.posts = posts
    }

    var body: RSS {
        RSS(
            .title(blog.name),
            .link(blog.url ?? ""),
            .atomLink((blog.url ?? "") + "/feed.xml"),
            .description(blog.about ?? ""),
            .language(.usEnglish), // TODO: Make this configurable
            .pubDate(posts.first?.publishedAt ?? .distantPast),
            .group(items)
        )
    }

    var items: [Node<RSS.ChannelContext>] {
        posts.map { post in
            .item(
                .guid(.text(post.permalink)),
                .title(post.title.replacing(#/`/#, with: "")),
                .link(post.permalink),
                .description(post.excerpt),
                .content(MarkdownDecorator().decorate(post.contents)),
                .pubDate(post.publishedAt)
            )
        }
    }
}
