//
//  ImageDownloaderTests.swift
//  SwiftUIRickAndMortyTests
//
//  Created by Görkem Gür on 14.12.2024.
//

import XCTest
@testable import SwiftUIRickAndMorty

final class ImageDownloaderTests: XCTestCase {
    var sut: ImageDownloaderManager!
    private var urlSession: URLSession!
    
    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLSession.self]
        urlSession = URLSession(configuration: configuration)
        sut = ImageDownloaderManager(session: urlSession)
    }
    
    override func tearDown() {
        MockURLSession.completionHandler = nil
        urlSession = nil
        sut = nil
        super.tearDown()
    }
    
    func testDownloadImageSuccess() async {
        // Given
        let expectation = XCTestExpectation(description: "Download image success")
        let validImageUrl = "https://valid-url.com/image.jpg"
        let mockImageData = Data("fake image data".utf8)
        var resultData: Data?
        var resultError: Error?
        
        MockURLSession.completionHandler = { request in
            return (
                HTTPURLResponse(
                    url: URL(string: validImageUrl)!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                mockImageData
            )
        }
        
        // When
        do {
            resultData = try await sut.downloadImage(validImageUrl)
            expectation.fulfill()
        } catch {
            resultError = error
            XCTFail("Image Download Should Be Success")
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(resultData)
        XCTAssertNil(resultError)
        XCTAssertEqual(resultData, mockImageData)
    }
    
    func testDownloadImageFail() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Download image failure")
        var resultError: NetworkError?
        
        MockURLSession.completionHandler = { _ in
            throw NetworkError.invalidURL
        }
        
        // When
        do {
            _ = try await sut.downloadImage("invalid-url")
        } catch {
            resultError = error as? NetworkError
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(resultError)
        XCTAssertEqual(resultError, NetworkError.invalidURL)
    }
}
