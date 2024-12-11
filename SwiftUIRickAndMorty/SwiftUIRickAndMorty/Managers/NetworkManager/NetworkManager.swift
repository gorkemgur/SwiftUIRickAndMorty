//
//  NetworkManager.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation

protocol NetworkService: AnyObject {
    func fetch<T: Decodable>(with endpoint: Endpoint) async throws -> T
}

final class NetworkManager: NetworkService {
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    private lazy var jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        return jsonDecoder
    }()
    
    func fetch<T: Decodable>(with endpoint: Endpoint) async throws -> T {
        guard let urlRequest = endpoint.createURLRequest() else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.failedResponse(statusCode: httpResponse.statusCode)
        }
        
        do {
            let decodedResponse = try jsonDecoder.decode(T.self, from: data)
            return decodedResponse
        } catch {
            throw NetworkError.decodeFailed(errorDescription: error.localizedDescription)
        }
    }
}
