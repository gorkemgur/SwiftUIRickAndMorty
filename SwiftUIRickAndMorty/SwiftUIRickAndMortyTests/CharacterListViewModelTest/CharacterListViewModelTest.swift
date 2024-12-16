//
//  CharacterListViewModelTest.swift
//  SwiftUIRickAndMortyTests
//
//  Created by Görkem Gür on 14.12.2024.
//

import XCTest
import Combine
@testable import SwiftUIRickAndMorty

final class CharacterListViewModelTest: XCTestCase {
    var sut: CharacterListViewModel!
    var mockNetworkManager: MockNetworkManager!
    var mockCacheManager: MockCacheManager!
    var mockImageDownloadService: MockImageDownloadService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockNetworkManager = MockNetworkManager()
        mockCacheManager = MockCacheManager()
        mockImageDownloadService = MockImageDownloadService()
        cancellables = Set<AnyCancellable>()
        sut = CharacterListViewModel(
            networkManager: mockNetworkManager,
            cacheManager: mockCacheManager,
            imageDownloadManager: mockImageDownloadService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkManager = nil
        mockCacheManager = nil
        mockImageDownloadService = nil
        cancellables = nil
        super.tearDown()
    }
    
    
    func testCharacterFetchSuccess() async {
        // Given
        let sampleJson = NetworkManagerTests.loadJsonFile()
        let invalidStates: [ViewState] = [.error(""), .noData, .idle,]
        mockNetworkManager.mockData = sampleJson
        let stateTracker = ViewModelStateTracker()
        let expectation = XCTestExpectation(description: "Characters should be fetched")
        
        sut.$viewState
            .receive(on: DispatchQueue.main)
        //Drop Idle State
            .dropFirst()
            .sink { viewState in
                Task {
                    await stateTracker.addState(viewState)
                }
                expectation.fulfill()
            }.store(in: &cancellables)
        
        //When
        await MainActor.run {
            sut.fetchRickAndMorty()
        }
        
        //Then
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let trackedStates = await stateTracker.getStates()
        
        await MainActor.run {
            XCTAssertEqual(trackedStates.first, .loading)
            XCTAssertEqual(trackedStates.last, .showData)
            XCTAssertFalse(trackedStates.contains(invalidStates))
            XCTAssertFalse(sut.characterList.isEmpty)
            XCTAssertEqual(sut.characterList.count, sut.filteredCharacters.count)
        }
    }
    
    func testCharacterFetchFail() async {
        // Given
        mockNetworkManager.shouldFail = true
        let stateTracker = ViewModelStateTracker()
        let expectation = XCTestExpectation(description: "Should fail with network error")
        
        sut.$viewState
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { viewState in
                Task {
                    await stateTracker.addState(viewState)
                }
                expectation.fulfill()
            }.store(in: &cancellables)
        
        // When
        await MainActor.run {
            sut.fetchRickAndMorty()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        
        let trackedStates = await stateTracker.getStates()
        
        await MainActor.run {
            XCTAssertEqual(trackedStates.first, .loading)
            XCTAssertEqual(trackedStates.last, .error("Failed Response With StatusCode:-1"))
            XCTAssertTrue(sut.characterList.isEmpty)
            XCTAssertTrue(sut.filteredCharacters.isEmpty)
        }
    }
    
    func testCharacterFetchWithPagination() async {
        // Given
        let sampleJson = NetworkManagerTests.loadJsonFile()
        mockNetworkManager.mockData = sampleJson
        let stateTracker = ViewModelStateTracker()
        let expectation = XCTestExpectation(description: "Pagination test")
        
        sut.$viewState
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { viewState in
                Task {
                    await stateTracker.addState(viewState)
                    expectation.fulfill()
                }
            }.store(in: &cancellables)
        
        // When
        await MainActor.run {
            sut.fetchRickAndMorty()
            
            sut.loadMorePages()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        await MainActor.run {
            XCTAssertFalse(sut.characterList.isEmpty, "Character List Must Be Filled")
            XCTAssertGreaterThanOrEqual(sut.characterList.count, 20, "After Pagination Must Be 20 Character")
            let uniqueIds = Set(sut.characterList.map { $0.id })
            XCTAssertEqual(uniqueIds.count, sut.characterList.count, "Must Not Be Duplicated Variables")
        }
    }
    
    func testCharacterFilterWithSearchText() async {
        // Given
        let sampleJson = NetworkManagerTests.loadJsonFile()
        mockNetworkManager.mockData = sampleJson
        let stateTracker = ViewModelStateTracker()
        let expectation = XCTestExpectation(description: "Searchable Test")
        
        sut.$viewState
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { viewState in
                Task {
                    await stateTracker.addState(viewState)
                }
            }.store(in: &cancellables)
        
        sut.$filteredCharacters
            .receive(on: DispatchQueue.main)
            .sink { receivedFilteredCharacters in
                expectation.fulfill()
            }.store(in: &cancellables)
        
        // When
        await MainActor.run {
            sut.fetchRickAndMorty()
            
            sut.loadMorePages()
            
            sut.searchText = "Bill"
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000) // Wait 500ms For SearchText Debounce In ViewModel
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.5)
        
        await MainActor.run {
            XCTAssertFalse(sut.characterList.isEmpty, "Character List Must Be Filled")
            XCTAssertGreaterThanOrEqual(sut.characterList.count, 20, "After Pagination Must Be 20 Character")
            let uniqueIds = Set(self.sut.characterList.map { $0.id })
            XCTAssertEqual(uniqueIds.count, sut.characterList.count, "Must Not Be Duplicated Variables")
            XCTAssertEqual(sut.filteredCharacters.count, 2)
            XCTAssertEqual(sut.searchText, "Bill")
            XCTAssertEqual(sut.filteredCharacters.last?.name, "Toxic Bill")
            XCTAssertNotEqual(sut.characterList.count, sut.filteredCharacters.count)
        }
    }
    
    func testFetchCharacterAndCacheCharacterImageSuccess() async {
        let sampleJson = NetworkManagerTests.loadJsonFile()
        mockNetworkManager.mockData = sampleJson
        let expectation = XCTestExpectation(description: "Characters image should be cached")
        
        sut.$characterList
            .receive(on: DispatchQueue.main)
            .sink { characterList in
                characterList.forEach { character in
                    do {
                        try self.mockCacheManager.setImageCache(
                            url: NSString(string: character.image ?? ""),
                            data: Data("\(character.name ?? "")".utf8)
                        )
                        
                        let cachedImageCount = self.mockCacheManager.cachedData.count
                        let retrievedImagesCount = characterList.compactMap { character -> Data? in
                            guard let imageUrl = character.image else { return nil }
                            return try? self.mockCacheManager.retrieveImageFromCache(with: imageUrl.asNSString)
                        }.count
                        
                        XCTAssertEqual(cachedImageCount, retrievedImagesCount, "Cached And Retrieved Count Must Be Same")
                        expectation.fulfill()
                        
                    } catch {
                        XCTFail("Cache Must Be Success")
                    }
                }
                
            }.store(in: &cancellables)
        
        //When
        await MainActor.run {
            sut.fetchRickAndMorty()
        }
        
        //Then
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(mockCacheManager.cachedData)
        XCTAssertFalse(mockCacheManager.didRateLimitExceeded, "Must Be False We Set MaxLimit To 100 And We Cached 20")
        XCTAssertTrue(mockCacheManager.didSetCacheCalled)
        XCTAssertTrue(mockCacheManager.didRetrieveCacheCalled)
        XCTAssertEqual(mockCacheManager.cachedData.count, 20)
    }
    
    func testFetchCharacterAndCacheCharacterImageFail() async {
        let sampleJson = NetworkManagerTests.loadJsonFile()
        mockNetworkManager.mockData = sampleJson
        mockCacheManager.maxRateLimit = 10
        let expectation = XCTestExpectation(description: "Characters image should be cached")
        
        sut.$characterList
            .receive(on: DispatchQueue.main)
            .sink { characterList in
                characterList.forEach { character in
                    do {
                        try self.mockCacheManager.setImageCache(
                            url: NSString(string: character.image ?? ""),
                            data: Data("\(character.name ?? "")".utf8)
                        )
                        
                        if self.mockCacheManager.cachedData.count > 10 {
                            XCTFail("Cache Must Be Failed For Limit Rate Exceeded")
                        }
                        
                    } catch {
                        print(error as NSError)
                        if (error as NSError).domain.caseInsensitiveCompare("CacheError") == .orderedSame {
                            expectation.fulfill()
                        }
                    }
                }
                
            }.store(in: &cancellables)
        
        //When
        await MainActor.run {
            sut.fetchRickAndMorty()
        }
        
        //Then
        await fulfillment(of: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(mockCacheManager.cachedData)
        XCTAssertTrue(mockCacheManager.didRateLimitExceeded, "Must Be True Becasue We Set Max Limit 10")
        XCTAssertTrue(mockCacheManager.didSetCacheCalled)
        XCTAssertFalse(mockCacheManager.didRetrieveCacheCalled)
        XCTAssertEqual(mockCacheManager.cachedData.count, 10)
    }
}

fileprivate actor ViewModelStateTracker {
    private(set) var states: [ViewState] = []
    
    func addState(_ state: ViewState) {
        states.append(state)
    }
    
    func getStates() -> [ViewState] {
        return states
    }
}
