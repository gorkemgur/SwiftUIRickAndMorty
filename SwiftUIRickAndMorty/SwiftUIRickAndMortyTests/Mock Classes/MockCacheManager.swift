//
//  MockCacheManager.swift
//  SwiftUIRickAndMortyTests
//
//  Created by Görkem Gür on 14.12.2024.
//

import Foundation
@testable import SwiftUIRickAndMorty

final class MockCacheManager: CacheService {
    var maxRateLimit: Int = 100
    
    var cachedData: [NSString: NSData] = [:]

    private(set) var didSetCacheCalled = false
    private(set) var didRateLimitExceeded = false
    func setImageCache(url: NSString, data: Data) throws {
        didSetCacheCalled = true
        
        if cachedData.count >= maxRateLimit {
            didRateLimitExceeded = true
            throw NSError(domain: "CacheError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])
        }
        
        cachedData[url] = data.asNSData
    }
    
    private(set) var didRetrieveCacheCalled = false
    var shouldFailRetrieve = false
    func retrieveImageFromCache(with url: NSString) throws -> Data? {
        didRetrieveCacheCalled = true
        
        if shouldFailRetrieve {
            throw CacheError.invalidData
        }
        
        return cachedData[url]?.asData
    }
    
    private(set) var allCacheClearCalled = false
    func clearAllCache() throws {
        allCacheClearCalled = true
        cachedData.removeAll()
    }
}
