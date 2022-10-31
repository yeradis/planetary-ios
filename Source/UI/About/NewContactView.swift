//
//  NewContactView.swift
//  Planetary
//
//  Created by Martin Dutra on 28/10/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import SwiftUI

struct NewContactView: View {

    var identity: Identity

    @State fileprivate var about: About?
    @State fileprivate var relationship: Relationship?
    @State fileprivate var socialStats: SocialStats?
    @State fileprivate var hashtags: [Hashtag]?

    func attributedSocialStats(from socialStats: SocialStats) -> AttributedString {
        let numberOfFollowers = socialStats.numberOfFollowers
        let numberOfFollows = socialStats.numberOfFollows
        let string = Localized.followStats.text

        var attributeContainer = AttributeContainer()
        attributeContainer.foregroundColor = .primaryTxt

        var attributedString = AttributedString(string)
        if let range = attributedString.range(of: "{{numberOfFollows}}") {
            attributedString.replaceSubrange(
                range,
                with: AttributedString("\(numberOfFollows)", attributes: attributeContainer)
            )
        }
        if let range = attributedString.range(of: "{{numberOfFollowers}}") {
            attributedString.replaceSubrange(
                range,
                with: AttributedString("\(numberOfFollowers)", attributes: attributeContainer)
            )
        }
        return attributedString
    }

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F08508"), Color(hex: "#F43F75")],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                .frame(width: 92, height: 92)
                .overlay(
                    ImageMetadataView(metadata: about?.image)
                        .cornerRadius(99)
                        .frame(width: 87, height: 87)
                        .scaledToFill()
                )
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(about?.nameOrIdentity ?? identity)
                            .foregroundColor(Color("primary-txt"))
                            .font(.headline)
                        Text(identity.prefix(7))
                            .font(.system(size: 12))
                            .foregroundColor(Color("secondary-txt"))
                    }
                    Spacer()
                    RelationshipView(relationship: relationship, compact: true) {

                    }
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                }
                Text(attributedSocialStats(from: socialStats ?? .zero))
                    .font(.caption)
                    .foregroundColor(Color.secondaryTxt)
                    .redacted(reason: socialStats == nil ? .placeholder : [])
                if let hashtags = hashtags, !hashtags.isEmpty {
                    Text(hashtags.map{$0.string}.joined(separator: " ").parseMarkdown())
                        .foregroundLinearGradient(LinearGradient(
                            colors: [Color(hex: "#F08508"), Color(hex: "#F43F75")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .task {
            Task.detached {
                do {
                    about = try await Bots.current.about(identity: identity)
                } catch {

                }
                if let currentIdentity = Bots.current.identity {
                    do {
                        relationship = try await Bots.current.relationship(from: currentIdentity, to: identity)
                    } catch {

                    }
                }
                do {
                    socialStats = try await Bots.current.socialStats(for: identity)
                } catch {
                    socialStats = .zero
                }
                do {
                    hashtags = try await Bots.current.hashtags(usedBy: identity, limit: 3)
                } catch {
                    hashtags = []
                }
            }

        }
    }
}

struct NewContactView_Previews: PreviewProvider {
    static let post: Post = {
        Caches.blobs.update(UIImage(named: "avatar1") ?? .remove, for: "&avatar1")
        Caches.blobs.update(UIImage(named: "avatar2") ?? .remove, for: "&avatar2")
        Caches.blobs.update(UIImage(named: "avatar3") ?? .remove, for: "&avatar3")
        Caches.blobs.update(UIImage(named: "avatar4") ?? .remove, for: "&avatar4")
        Caches.blobs.update(UIImage(named: "avatar5") ?? .remove, for: "&avatar5")
        let post = Post(
            blobs: [
                Blob(identifier: "&avatar1"),
                Blob(identifier: "&avatar2"),
                Blob(identifier: "&avatar3"),
                Blob(identifier: "&avatar4"),
                Blob(identifier: "&avatar5")
            ],
            branches: nil,
            hashtags: nil,
            mentions: nil,
            root: nil,
            text: "Hello"
        )
        return post
    }()

    static var previews: some View {
        NewContactView(identity: .null)
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)


    }
}
