//
//  CharacterListViewModel.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation
import Combine

enum ViewState: Equatable {
    case idle
    case loading
    case noData
    case showData
    case error(String)
}

final class CharacterListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var viewState: ViewState = .idle
    @Published var searchText: String = ""
    @Published var characterList: [CharacterResult] = []
    @Published var filteredCharacters: [CharacterResult] = []
    
    // MARK: - Dependencies
    private let networkManager: NetworkService
    private let cacheManager: CacheService
    private let imageDownloadManager: ImageDownloadService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var currentFetchTask: Task<Void, Never>?
    private var currentImageDownloadTask: Task<Data?, Never>?
    private var perPage = 10
    private var currentPage = 1
    private var totalPageCount = 0
    
    // MARK: - Initialization
    init(
        networkManager: NetworkService,
        cacheManager: CacheService,
        imageDownloadManager: ImageDownloadService
    ) {
        self.networkManager = networkManager
        self.cacheManager = cacheManager
        self.imageDownloadManager = imageDownloadManager
        setupSearchSubscriber()
    }
    
    private func setupSearchSubscriber() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterCharacters(with: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func filterCharacters(with searchText: String) {
        if searchText.isEmpty {
            filteredCharacters = characterList
        } else {
            filteredCharacters = characterList.filter { character in
                character.name?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func cancelCurrentTask() {
        currentFetchTask?.cancel()
        currentFetchTask = nil
    }
    
    private func cancelImageTask() {
        currentImageDownloadTask?.cancel()
        currentImageDownloadTask = nil
    }
    
    deinit {
        cancelCurrentTask()
        cancelImageTask()
    }
}

// MARK: - Network Request Methods
extension CharacterListViewModel {
    func fetchRickAndMorty() {
        cancelCurrentTask()
        
        currentFetchTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            if self.characterList.isEmpty {
                self.viewState = .loading
            }
            
            do {
                try Task.checkCancellation()
                
                let characterResponse: Character = try await networkManager.fetch(
                    with: CharacterEndpoint.getCharacters(page: currentPage)
                )
                
                try Task.checkCancellation()
                
                self.totalPageCount = characterResponse.info.pages
                self.handleNewCharacters(newCharacters: characterResponse.results)
                
                self.viewState = characterList.isEmpty ? .noData : .showData
            } catch {
                if let networkError = error as? NetworkError {
                    self.viewState = .error(networkError.errorDescription)
                }
            }
        }
    }
    
    private func handleNewCharacters(newCharacters: [CharacterResult]) {
        if characterList.isEmpty {
            characterList = newCharacters
        } else {
            newCharacters.forEach { character in
                if !characterList.contains(where: { $0.id == character.id }) {
                    characterList.append(character)
                }
            }
        }
        filterCharacters(with: searchText)
    }
    
    func loadMorePages() {
        guard viewState != .loading,
              currentPage < totalPageCount else {
            return
        }
        
        currentPage += 1
        fetchRickAndMorty()
    }
}

// MARK: - Image Cache Methods
extension CharacterListViewModel {
    func handleImageLoading(for urlString: String) async -> Data? {
        // Cache kontrolü
        if let cachedImage = retrieveImageFromCache(urlString) {
            return cachedImage
        }
        
        currentImageDownloadTask = Task { @MainActor [weak self] in
            guard let self = self else { return nil }
            
            do {
                try Task.checkCancellation()
                if let downloadedData = try await imageDownloadManager.downloadImage(urlString) {
                    self.cacheImage(downloadedData, for: urlString)
                    try Task.checkCancellation()
                    return downloadedData
                }
            } catch {
                print("Image download error: \(error.localizedDescription)")
            }
            return nil
        }
        
        return await currentImageDownloadTask?.value
    }
    
    private func cacheImage(_ imageData: Data, for urlString: String) {
        cacheManager.setImageCache(url: urlString.asNSString, data: imageData)
    }
    
    private func retrieveImageFromCache(_ urlString: String) -> Data? {
        return cacheManager.retrieveImageFromCache(with: urlString.asNSString)
    }
    
}

