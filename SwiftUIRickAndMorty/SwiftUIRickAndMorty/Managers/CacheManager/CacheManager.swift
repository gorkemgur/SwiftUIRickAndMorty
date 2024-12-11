//
//  CacheManager.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation

protocol CacheService {
    func setImageCache(url: NSString, data: Data)
    func retrieveImageFromCache(with url: NSString) -> Data?
    func clearAllCache()
}

final class CacheManager: CacheService {
    private let cache = NSCache<NSString, NSData>()
    
    init(
        countLimit: Int = 100,
        totalCostLimit: Int = 50 * 1024 * 1024 //50MB
    ) {
        self.cache.countLimit = countLimit
        self.cache.totalCostLimit = totalCostLimit
    }
    
    func setImageCache(url: NSString, data: Data) {
        self.cache.setObject(data.asNSData, forKey: url)
    }
    
    func retrieveImageFromCache(with url: NSString) -> Data? {
        cache.object(forKey: url)?.asData
    }
    
    func clearAllCache() {
        cache.removeAllObjects()
    }
}
