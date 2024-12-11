//
//  CharacterEndpoint.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation

enum CharacterEndpoint: Endpoint {
    case getCharacters(page: Int) //Fetch All List
    case getCharacter(characterId: Int) //Fetch Character Detail
    
    var path: String {
        switch self {
        case .getCharacters(_):
            return "/character"
        case .getCharacter(let characterId):
            return "/character/\(characterId)"
        }
    }
    
    var queryParameters: [String : String]? {
        switch self {
        case .getCharacters(let page):
            ["page" : "\(page)"]
        default:
            nil
        }
    }
    
    var httpMethod: HTTPMethod {
        .get
    }
}
