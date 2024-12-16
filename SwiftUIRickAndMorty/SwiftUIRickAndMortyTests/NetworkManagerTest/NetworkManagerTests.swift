//
//  NetworkManagerTests.swift
//  SwiftUIRickAndMortyTests
//
//  Created by Görkem Gür on 14.12.2024.
//

import XCTest
@testable import SwiftUIRickAndMorty

final class NetworkManagerTests: XCTestCase {
    var sut: NetworkManager!
    
    override func setUp() {
        sut = NetworkManager(urlSession: XCTest.createMockURLSession())
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        MockURLSession.completionHandler = nil
        super.tearDown()
    }
    
    
    func testSuccessDataFetch() async {
        //Given
        let sampleJson = NetworkManagerTests.loadJsonFile()
        var fetchedCharacterResponse: Character?
        var networkError: NetworkError?
        let mockEndpoint = MockEndpoint.fetch(isValid: true)
        let mockUrl = mockEndpoint.createURLRequest()?.url
        let expectation = XCTestExpectation(description: "Should Be Fetched Data")
        
        MockURLSession.completionHandler = { request in
            let response = HTTPURLResponse(url: mockUrl!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (response, sampleJson)
        }
        
        //When
        do {
            fetchedCharacterResponse = try await sut.fetch(with: mockEndpoint)
            expectation.fulfill()
        } catch {
            networkError = error as? NetworkError
        }
        
        //Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNil(networkError)
        XCTAssertNotNil(fetchedCharacterResponse)
    }
    
    
    func testFailedDataFetchInvalidUrl() async {
        //Given
        var fetchedCharacterResponse: Character?
        var networkError: NetworkError?
        let mockEndpoint = MockEndpoint.fetch(isValid: false)
        let expectation = XCTestExpectation(description: "Should Be Fetched Data")
        
        MockURLSession.completionHandler = { _ in
            throw NetworkError.invalidURL
        }
        
        //When
        do {
            fetchedCharacterResponse = try await sut.fetch(with: mockEndpoint)
            XCTFail("Should Be Failed")
        } catch {
            networkError = error as? NetworkError
            expectation.fulfill()
        }
        
        //Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNil(fetchedCharacterResponse)
        XCTAssertNotNil(networkError)
    }
    
    func testFailedDataFetchDecodeError() async {
        //Given
        let sampleJson = NetworkManagerTests.loadJsonFile(isCorruptedJson: true)
        var fetchedCharacterResponse: Character?
        var networkError: NetworkError?
        let mockEndpoint = MockEndpoint.fetch(isValid: true)
        let mockUrl = mockEndpoint.createURLRequest()?.url
        let expectation = XCTestExpectation(description: "Should Be Fetched Data")
        
        MockURLSession.completionHandler = { request in
            let response = HTTPURLResponse(url: mockUrl!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (response, sampleJson)
        }
        
        //When
        do {
            fetchedCharacterResponse = try await sut.fetch(with: mockEndpoint)
        } catch {
            networkError = error as? NetworkError
            expectation.fulfill()
        }
        
        //Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNil(fetchedCharacterResponse)
        XCTAssertNotNil(networkError)
    }
}


extension XCTest {
    static func createMockURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLSession.self]
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }
}

enum MockEndpoint: Endpoint {
    case fetch(isValid: Bool)
    
    var path: String {
        switch self {
        case .fetch(let isValid):
            return isValid ? "/fetch" : "fetch//"
        }
    }
    
    var baseURL: String {
        switch self {
        case .fetch(let isValid):
            return isValid ? "mock.com" : "mock.com/api"
        }
    }
    
    var httpMethod: HTTPMethod {
        .get
    }
}

extension NetworkManagerTests {
    static func loadJsonFile(isCorruptedJson: Bool = false) -> Data {
        let sampleJsonURL = Bundle(for: NetworkManagerTests.self).url(forResource: isCorruptedJson ? "corruptedSampleJson" : "sampleJson" , withExtension: "json")
        return try! Data(contentsOf: sampleJsonURL!)
    }
}
