//
//  MockImageDownloadService.swift
//  SwiftUIRickAndMortyTests
//
//  Created by Görkem Gür on 14.12.2024.
//

import Foundation
@testable import SwiftUIRickAndMorty

final class MockImageDownloadService: ImageDownloadService {
    var shouldFail = false
    var mockData: Data?
    var calledDownloadImageCount = 0
    
    func downloadImage(_ url: String) async throws -> Data? {
        calledDownloadImageCount += 1
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        if shouldFail {
            return nil
        }
        return mockData
    }
}
