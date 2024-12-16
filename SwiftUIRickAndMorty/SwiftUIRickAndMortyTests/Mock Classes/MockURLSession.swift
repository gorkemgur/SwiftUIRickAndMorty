//
//  MockURLSession.swift
//  SwiftUIRickAndMortyTests
//
//  Created by Görkem Gür on 14.12.2024.
//

import Foundation
import XCTest
@testable import SwiftUIRickAndMorty

import XCTest

final class MockURLSession: URLProtocol {
    
    static var completionHandler: ((URLRequest) throws -> (HTTPURLResponse?, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let completionHandler = MockURLSession.completionHandler else {
            XCTFail("handler not found")
            return
        }
        
        do {
            let (response, data) = try completionHandler(request)
            
            client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    
    override func stopLoading() {}
}
