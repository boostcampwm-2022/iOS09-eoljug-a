//
//  ScrapViewModel.swift
//  Eoljuga
//
//  Created by youtak on 2022/11/21.
//

import Combine
import Foundation

import FirebaseFirestore

typealias FeedWithOrder = (order: Int, feed: Feed)

final class ScrapPageViewModel {

    var scrapFeedData: [Feed] = []
    private var willRequestFeedID: [String] = []

    private var cellUpdate = PassthroughSubject<IndexPath, Never>()
    var cancelBag = Set<AnyCancellable>()

    private let requestFeedCount = 7
    private var isFetching: Bool = false
    private var canFetchMoreFeed: Bool = true

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let viewRefresh: AnyPublisher<Bool, Never>
        let pagination: AnyPublisher<Void, Never>
    }

    enum FetchResult {
        case fetchFail(error: Error)
        case fetchSuccess
    }

    struct Output {
        var fetchResult = PassthroughSubject<FetchResult, Never>()
        var cellUpdate: AnyPublisher<IndexPath, Never>
    }

    func transform(input: Input) -> Output {
        let output = Output(
            cellUpdate: cellUpdate.eraseToAnyPublisher()
        )

        input.viewDidLoad
            .sink { [weak self] _ in
                self?.fetchScrapFeed(output: output)
            }
            .store(in: &cancelBag)

        input.viewRefresh
            .sink { [weak self] _ in
                self?.fetchScrapFeed(output: output)
            }
            .store(in: &cancelBag)

        input.pagination
            .sink { [weak self] _ in
                self?.paginateFeed(output: output)
            }
            .store(in: &cancelBag)

        return output
    }

    func dequeueCellViewModel(at index: Int) -> FeedScrapViewModel {
        let feedScrapViewModel = FeedScrapViewModel(feedUUID: scrapFeedData[index].feedUUID)
        feedScrapViewModel.getScrapCountUp
            .sink { [weak self] state in
                guard let self = self else { return }
                if state {
                    self.scrapFeedData[index].scrapCountUp()
                } else {
                    self.scrapFeedData[index].scrapCountDown()
                }
                let indexPath = IndexPath(row: index, section: 0)
                self.cellUpdate.send(indexPath)
            }
            .store(in: &cancelBag)

        return feedScrapViewModel
    }

    private func getUserScarpUUID() -> [String] {
        return UserManager.shared.user.scrapFeedUUIDs
    }

    private func initScrapFeedUUID() {
        willRequestFeedID = getUserScarpUUID()
    }

    private func getLatestFeedUUID() -> [String] {
        var result: [String] = []
        for _ in 0..<requestFeedCount {
            let feedUUID = willRequestFeedID.popLast()
            if let feedUUID = feedUUID {
                result.append(feedUUID)
            }
        }
        return result
    }

    private func fetchScrapFeed(output: Output) {
        initScrapFeedUUID()
        Task {
            do {
                guard !isFetching else { return }
                isFetching = true
                canFetchMoreFeed = true

                let scrapFeeds = try await fetchFeeds()
                scrapFeedData = scrapFeeds
                output.fetchResult.send(.fetchSuccess)

                isFetching = false
            } catch {
            isFetching = false
            }
        }
    }

    private func paginateFeed(output: Output) {
        Task {
            do {
                guard !isFetching, canFetchMoreFeed else { return }
                guard !willRequestFeedID.isEmpty else {
                    canFetchMoreFeed = false
                    return
                }
                isFetching = true
                canFetchMoreFeed = true

                let scrapFeeds = try await fetchFeeds()
                scrapFeedData.append(contentsOf: scrapFeeds)
                output.fetchResult.send(.fetchSuccess)

                isFetching = false
            } catch {
            isFetching = false
            }
        }
    }

    private func fetchFeeds() async throws -> [Feed] {
        try await withThrowingTaskGroup(of: FeedWithOrder.self, body: { taskGroup in
            let requestFeedUUIDs = getLatestFeedUUID()
            var scrapFeeds: [FeedWithOrder] = []

            requestFeedUUIDs.enumerated().forEach { index, feedUUID in
                taskGroup.addTask {
                    let feed = try await self.fetchFeed(uuid: feedUUID)
                    return FeedWithOrder(order: index, feed: feed)
                }
            }

            for try await feed in taskGroup {
                scrapFeeds.append(feed)
            }

            let result = scrapFeeds
                .sorted { $0.order < $1.order }
                .map { $0.feed }

            return result
        })
    }

    private func fetchFeed(uuid: String) async throws -> Feed {
        let feedDTO = try await fetchFeedDTO(uuid: uuid)
        let feedWriter = try await fetchFeedWriter(uuid: feedDTO.writerUUID)
        let scrapCount = try await countFeedScrapCount(uuid: uuid)
        let feed = Feed(feedDTO: feedDTO, feedWriter: feedWriter, scrapCount: scrapCount)
        return feed
    }

    private func fetchFeedDTO(uuid: String) async throws -> FeedDTO {
        try await withCheckedThrowingContinuation({ continuation in
            FirestoreCollection.feed.reference
                .document(uuid)
                .getDocument { documentSnapShot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let snapShot = documentSnapShot,
                          let feedDTOData = snapShot.data()
                    else {
                        continuation.resume(throwing: FirebaseError.fetchUserError)
                        return
                    }
                    let feedDTO = FeedDTO(data: feedDTOData)
                    continuation.resume(returning: feedDTO)
                }
        })
    }

    private func fetchFeedWriter(uuid: String) async throws -> FeedWriter {
        try await withCheckedThrowingContinuation({ continuation in
            FirestoreCollection.user.reference
                .document(uuid)
                .getDocument { documentSnapShot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let snapShot = documentSnapShot,
                          let userData = snapShot.data()
                    else {
                        continuation.resume(throwing: FirebaseError.fetchUserError)
                        return
                    }
                    let feedWriter = FeedWriter(data: userData)
                    continuation.resume(returning: feedWriter)
                }
        })
    }

    private func countFeedScrapCount(uuid: String) async throws -> Int {
        let path = ["feed", uuid, "scrapUsers"].joined(separator: "/")
        let countQuery = Firestore.firestore().collection(path).count
        let collectionCount = try await countQuery.getAggregation(source: .server)
        return Int(truncating: collectionCount.count)
    }
}
