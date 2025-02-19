//
//  FeedStrategyTests.swift
//  UnitTests
//
//  Created by Matthew Lorentz on 5/17/22.
//  Copyright © 2022 Verse Communications Inc. All rights reserved.
//

import XCTest

// swiftlint:disable force_unwrapping function_body_length

/// Tests to make sure our `FeedStrategy`s fetch the posts we expect.
class FeedStrategyTests: XCTestCase {
    
    var tmpURL = URL(string: "unset")!
    var db = ViewDatabase()
    let testAuthor: Identity = DatabaseFixture.exampleFeed.identities[0]

    override func setUpWithError() throws {
        try super.setUpWithError()
        db.close()
        
        // get random location for the new db
        self.tmpURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("/viewDBtest-feedFill2"))
        
        do {
            try FileManager.default.removeItem(at: self.tmpURL)
        } catch {
            // ignore - most likely not exists
        }
        
        try FileManager.default.createDirectory(at: self.tmpURL, withIntermediateDirectories: true)
        
        // open DB
        let dbPath = tmpURL.absoluteString.replacingOccurrences(of: "file://", with: "")
        try db.open(path: dbPath, user: testAuthor, maxAge: -60 * 60 * 24 * 30 * 48)
    }
    
    override func tearDown() {
        super.tearDown()
        db.close()
    }
    
    // MARK: - RecentlyActivePostsAndContactsAlgorithm

    func testRecentlyActivePostsAndContactsAlgorithm() throws {
        let referenceDate: Double = 1_652_813_189_000 // May 17, 2022 in millis
        let receivedDate: Double = 1_652_813_515_000 // May 17, 2022 in millis
        let alice = DatabaseFixture.exampleFeed.identities[1]
        let bob = DatabaseFixture.exampleFeed.identities[2]
        
        let post0 = MessageFixtures.post(
            key: "%0",
            sequence: 0,
            timestamp: referenceDate + 0,
            receivedTimestamp: receivedDate,
            receivedSeq: 0,
            author: testAuthor
        )
        let follow1 = MessageFixtures.message(
            key: "%1",
            sequence: 1,
            content: Content(from: Contact(contact: alice, following: true)),
            timestamp: referenceDate + 1,
            receivedTimestamp: receivedDate,
            receivedSeq: 1,
            author: testAuthor
        )
        let about2 = MessageFixtures.message(
            key: "%2",
            sequence: 2,
            content: Content(from: About(about: alice, name: "Alice")),
            timestamp: referenceDate + 2,
            receivedTimestamp: receivedDate,
            receivedSeq: 2,
            author: alice
        )
        let post3 = MessageFixtures.post(
            key: "%3",
            sequence: 3,
            timestamp: referenceDate + 3,
            receivedTimestamp: receivedDate,
            receivedSeq: 3,
            author: testAuthor
        )
        let reply4 = MessageFixtures.message(
            key: "%4",
            sequence: 4,
            content: Content(
                from: Post(branches: ["%0"], root: "%0", text: "reply")
            ),
            timestamp: referenceDate + 4,
            receivedTimestamp: receivedDate,
            receivedSeq: 4,
            author: bob
        )
        let post5 = MessageFixtures.post(
            key: "%5",
            sequence: 5,
            timestamp: referenceDate + 5,
            receivedTimestamp: receivedDate,
            receivedSeq: 5,
            author: testAuthor
        )
        
        try db.fillMessages(msgs: [post0, follow1, about2, post3, reply4, post5])
        
        let strategy = RecentlyActivePostsAndContactsAlgorithm()
        let proxy = try db.paginatedFeed(with: strategy)
        
        XCTAssertEqual(proxy.count, 4)
        XCTAssertEqual(proxy.messageBy(index: 0), post5)
        XCTAssertEqual(proxy.messageBy(index: 1), post0)
        XCTAssertEqual(proxy.messageBy(index: 2), post3)
        XCTAssertEqual(proxy.messageBy(index: 3), follow1)

        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%5"), 0)
        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%0"), 1)
        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%3"), 2)
        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%1"), 3)
    }
    
    /// Verifies that the recently active posts and contacts algorithm does not push old posts to the top when they
    /// receive a vote.
    func testRecentlyActivePostsAndContactsAlgorithmDoesNotCountVotes() throws {
        let referenceDate: Double = 1_652_813_189_000 // May 17, 2022 in millis
        let receivedDate: Double = 1_652_813_515_000 // May 17, 2022 in millis
        
        let post1 = MessageFixtures.post(
            key: "%1",
            sequence: 1,
            timestamp: referenceDate + 1,
            receivedTimestamp: receivedDate,
            receivedSeq: 1,
            author: testAuthor
        )
        let post2 = MessageFixtures.post(
            key: "%2",
            sequence: 2,
            timestamp: referenceDate + 2,
            receivedTimestamp: receivedDate,
            receivedSeq: 2,
            author: testAuthor
        )
        // Vote on post 1, to verify it doesn't come to the top.
        let vote3 = MessageFixtures.message(
            sequence: 3,
            content: Content(from: ContentVote(
                link: "%1",
                value: 1,
                expression: nil,
                root: "%1",
                branches: []
            )),
            timestamp: referenceDate + 2,
            receivedTimestamp: receivedDate,
            receivedSeq: 2,
            author: testAuthor
        )
        
        try db.fillMessages(msgs: [post1, post2, vote3])
        
        let strategy = RecentlyActivePostsAndContactsAlgorithm()
        let proxy = try db.paginatedFeed(with: strategy)
        
        XCTAssertEqual(proxy.count, 2)
        XCTAssertEqual(proxy.messageBy(index: 0), post2)
        XCTAssertEqual(proxy.messageBy(index: 1), post1)
    }

    func testPostsAndContactsAlgorithm() throws {
        let referenceDate: Double = 1_652_813_189_000 // May 17, 2022 in millis
        let receivedDate: Double = 1_652_813_515_000 // May 17, 2022 in millis
        let alice = DatabaseFixture.exampleFeed.identities[1]
        let bob = DatabaseFixture.exampleFeed.identities[2]

        let post0 = MessageFixtures.post(
            key: "%0",
            sequence: 0,
            timestamp: referenceDate + 0,
            receivedTimestamp: receivedDate,
            receivedSeq: 0,
            author: testAuthor
        )
        let follow1 = MessageFixtures.message(
            key: "%1",
            sequence: 1,
            content: Content(from: Contact(contact: alice, following: true)),
            timestamp: referenceDate + 1,
            receivedTimestamp: receivedDate,
            receivedSeq: 1,
            author: testAuthor
        )
        let about2 = MessageFixtures.message(
            key: "%2",
            sequence: 2,
            content: Content(from: About(about: alice, name: "Alice")),
            timestamp: referenceDate + 2,
            receivedTimestamp: receivedDate,
            receivedSeq: 2,
            author: alice
        )
        let post3 = MessageFixtures.post(
            key: "%3",
            sequence: 3,
            timestamp: referenceDate + 3,
            receivedTimestamp: receivedDate,
            receivedSeq: 3,
            author: testAuthor
        )
        let reply4 = MessageFixtures.message(
            key: "%4",
            sequence: 4,
            content: Content(
                from: Post(branches: ["%0"], root: "%0", text: "reply")
            ),
            timestamp: referenceDate + 4,
            receivedTimestamp: receivedDate,
            receivedSeq: 4,
            author: bob
        )
        let post5 = MessageFixtures.post(
            key: "%5",
            sequence: 5,
            timestamp: referenceDate + 5,
            receivedTimestamp: receivedDate,
            receivedSeq: 5,
            author: testAuthor
        )

        try db.fillMessages(msgs: [post0, follow1, about2, post3, reply4, post5])

        let strategy = PostsAndContactsAlgorithm()
        let proxy = try db.paginatedFeed(with: strategy)

        XCTAssertEqual(proxy.count, 4)
        XCTAssertEqual(proxy.messageBy(index: 0), post5)
        XCTAssertEqual(proxy.messageBy(index: 1), post3)
        XCTAssertEqual(proxy.messageBy(index: 2), follow1)
        XCTAssertEqual(proxy.messageBy(index: 3), post0)

        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%5"), 0)
        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%3"), 1)
        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%1"), 2)
        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%0"), 3)
    }

    func testPostsAlgorithm() throws {
        let referenceDate: Double = 1_652_813_189_000 // May 17, 2022 in millis
        let receivedDate: Double = 1_652_813_515_000 // May 17, 2022 in millis
        let alice = DatabaseFixture.exampleFeed.identities[1]
        let bob = DatabaseFixture.exampleFeed.identities[2]

        let post0 = MessageFixtures.post(
            key: "%0",
            sequence: 0,
            timestamp: referenceDate + 0,
            receivedTimestamp: receivedDate,
            receivedSeq: 0,
            author: testAuthor
        )
        let follow1 = MessageFixtures.message(
            key: "%1",
            sequence: 1,
            content: Content(from: Contact(contact: alice, blocking: false)),
            timestamp: referenceDate + 1,
            receivedTimestamp: receivedDate,
            receivedSeq: 1,
            author: testAuthor
        )
        let about2 = MessageFixtures.message(
            key: "%2",
            sequence: 2,
            content: Content(from: About(about: alice, name: "Alice")),
            timestamp: referenceDate + 2,
            receivedTimestamp: receivedDate,
            receivedSeq: 2,
            author: alice
        )
        let post3 = MessageFixtures.post(
            key: "%3",
            sequence: 3,
            timestamp: referenceDate + 3,
            receivedTimestamp: receivedDate,
            receivedSeq: 3,
            author: testAuthor
        )
        let reply4 = MessageFixtures.message(
            key: "%4",
            sequence: 4,
            content: Content(
                from: Post(branches: ["%0"], root: "%0", text: "reply")
            ),
            timestamp: referenceDate + 4,
            receivedTimestamp: receivedDate,
            receivedSeq: 4,
            author: bob
        )
        let post5 = MessageFixtures.post(
            key: "%5",
            sequence: 5,
            timestamp: referenceDate + 5,
            receivedTimestamp: receivedDate,
            receivedSeq: 5,
            author: testAuthor
        )

        try db.fillMessages(msgs: [post0, follow1, about2, post3, reply4, post5])

        let strategy = PostsAlgorithm(wantPrivate: false, onlyFollowed: true)
        let proxy = try db.paginatedFeed(with: strategy)

        XCTAssertEqual(proxy.count, 3)
        XCTAssertEqual(proxy.messageBy(index: 0), post5)
        XCTAssertEqual(proxy.messageBy(index: 1), post3)
        XCTAssertEqual(proxy.messageBy(index: 2), post0)

        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%5"), 0)
        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%3"), 1)
        XCTAssertEqual(try db.numberOfRecentPosts(with: strategy, since: "%0"), 2)
    }
    
    // MARK: - PostsAlgorithm
    
    /// Verifies that posts from blocked users do not show up in the discover feed.
    func testDiscoverAlgorithmHidesBlocks() throws {
        // Arrange
        let referenceDate = Date().millisecondsSince1970 // May 17, 2022 in millis
        let receivedDate = Date().millisecondsSince1970 // May 17, 2022 in millis
        let alice = DatabaseFixture.exampleFeed.identities[1]
        
        let alicePost = MessageFixtures.post(
            key: "%1",
            sequence: 1,
            timestamp: referenceDate + 1,
            receivedTimestamp: receivedDate,
            receivedSeq: 1,
            author: alice
        )
        let blockAlice = MessageFixtures.message(
            key: "%2",
            sequence: 2,
            content: Content(from: Contact(contact: alice, blocking: true)),
            timestamp: referenceDate + 2,
            receivedTimestamp: receivedDate,
            receivedSeq: 2,
            author: testAuthor
        )
        
        let strategy = PostsAlgorithm(wantPrivate: false, onlyFollowed: false)
        
        // Act
        try db.fillMessages(msgs: [alicePost])
        var proxy = try db.paginatedFeed(with: strategy)
        
        XCTAssertEqual(proxy.count, 1)
        
        try db.fillMessages(msgs: [blockAlice])
        proxy = try db.paginatedFeed(with: strategy)
        
        XCTAssertEqual(proxy.count, 0)
    }
}
