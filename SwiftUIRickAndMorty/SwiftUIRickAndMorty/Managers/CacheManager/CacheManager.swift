//
//  CacheManager.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation

protocol CacheService {
    func setImageCache(url: NSString, data: Data) throws
    func retrieveImageFromCache(with url: NSString) throws -> Data?
    func clearAllCache() throws
}

final class CacheManager: CacheService {
    private let cache = NSCache<NSString, NSData>()
    private var cachedUrls: Set<NSString> = []
    
    init(
        countLimit: Int = 100,
        totalCostLimit: Int = 50 * 1024 * 1024 //50MB
    ) {
        self.cache.countLimit = countLimit
        self.cache.totalCostLimit = totalCostLimit
    }
    
    func setImageCache(url: NSString, data: Data) throws {
        guard data.count > 0 else {
            throw CacheError.invalidData
        }
        
        if !cachedUrls.contains(url) && cachedUrls.count >= cache.countLimit {
            throw CacheError.cacheLimitExceeded
        }
        
        cache.setObject(data.asNSData, forKey: url)
        cachedUrls.insert(url)
    }
    
    func retrieveImageFromCache(with url: NSString) throws -> Data? {
        guard let cachedData = cache.object(forKey: url)?.asData else {
            throw CacheError.itemNotFound
        }
        
        return cachedData
    }
    
    func clearAllCache() throws {
        cache.removeAllObjects()
        cachedUrls.removeAll()
    }
}


enum CacheError: Error {
    case invalidData
    case cacheLimitExceeded
    case itemNotFound
    case clearCacheError
}
