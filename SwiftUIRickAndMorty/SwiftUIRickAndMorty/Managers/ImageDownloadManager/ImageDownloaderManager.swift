//
//  ImageDownloaderManager.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation

protocol ImageDownloadService: AnyObject {
    func downloadImage(_ url: String) async throws -> Data?
}

final class ImageDownloaderManager: ImageDownloadService {
    
    func downloadImage(_ url: String) async throws -> Data? {
        
        guard let url = URL(string: url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } catch {
            throw error
        }
    }
}
