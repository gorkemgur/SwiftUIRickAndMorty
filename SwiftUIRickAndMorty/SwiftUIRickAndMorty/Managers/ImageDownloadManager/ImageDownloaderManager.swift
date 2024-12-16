//
//  ImageDownloaderManager.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation
import UIKit

protocol ImageDownloadService: AnyObject {
    func downloadImage(_ url: String) async throws -> Data?
}

final class ImageDownloaderManager: ImageDownloadService {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func downloadImage(_ url: String) async throws -> Data? {
        guard let url = URL(string: url), await UIApplication.shared.canOpenURL(url) else {
            throw NetworkError.invalidURL
        }
        
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return data
    }
}
