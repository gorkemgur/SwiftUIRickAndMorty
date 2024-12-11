//
//  Character.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation

struct Character: Decodable {
    let info: InfoModel
    let results: [CharacterResult]
}

struct InfoModel: Decodable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?
}

struct CharacterResult: Decodable, Identifiable {
    let id: Int
    let name: String?
    let status: String?
    let gender: String?
    let image: String?
}

extension Character {
    static var mockData: Self {
        .init(info: InfoModel(count: 10, pages: 1, next: "", prev: ""), results: [CharacterResult(id: 0, name: "Mock Name", status: "Mock Status", gender: "Male", image: "")])
    }
}
