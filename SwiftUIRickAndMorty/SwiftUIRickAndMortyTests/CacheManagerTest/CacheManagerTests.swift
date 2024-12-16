//
//  CacheManagerTests.swift
//  SwiftUIRickAndMortyTests
//
//  Created by Görkem Gür on 14.12.2024.
//

import XCTest
@testable import SwiftUIRickAndMorty

final class CacheManagerTests: XCTestCase {
    var sut: CacheManager!
    
    override func setUp() {
        super.setUp()
        sut = CacheManager(countLimit: 2)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testImageRetrieveSuccess() {
        // Given
        let mockUrl = NSString(string: "TestURL")
        let mockData = Data("mockData".utf8)
        
        // When & Then
        do {
            try sut.setImageCache(url: mockUrl, data: mockData)
            let cachedData = try sut.retrieveImageFromCache(with: mockUrl)
            XCTAssertEqual(cachedData, mockData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCacheLimitExceededError() {
        // Given
        let mockUrls: [NSString] = [NSString(string: "test1"), NSString(string: "test2"), NSString(string: "test3")]
        let testData = Data("TestData".utf8)
        
        // When & Then
        do {
            try mockUrls.forEach { try sut.setImageCache(url: $0, data: testData) }
            XCTFail("Should throw cacheLimitExceeded error")
        } catch CacheError.cacheLimitExceeded {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidDataError() {
        // Given
        let mockUrl = NSString(string: "TestURL")
        let emptyData = Data()
        
        // When & Then
        do {
            try sut.setImageCache(url: mockUrl, data: emptyData)
            XCTFail("Should throw invalidData error")
        } catch CacheError.invalidData {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testItemNotFoundError() {
        // Given
        let nonExistentUrl = NSString(string: "nonExistentURL")
        
        // When & Then
        do {
            _ = try sut.retrieveImageFromCache(with: nonExistentUrl)
            XCTFail("Should throw itemNotFound error")
        } catch CacheError.itemNotFound {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testClearCacheError() {
        // Given
        let mockUrl = NSString(string: "TestURL")
        let mockData = Data("mockData".utf8)
        
        // When & Then
        do {
            try sut.setImageCache(url: mockUrl, data: mockData)
            try sut.clearAllCache()
            
            _ = try sut.retrieveImageFromCache(with: mockUrl)
            XCTFail("Should throw itemNotFound error after clearing cache")
        } catch CacheError.itemNotFound {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
