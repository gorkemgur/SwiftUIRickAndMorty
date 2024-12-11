//
//  Data+Extension.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation
import UIKit
import SwiftUI

extension Data {
    var asNSData: NSData {
        return NSData(data: self)
    }
    
    var asImage: Image {
        if let uiimage = UIImage(data: self) {
            return Image(uiImage: uiimage)
        }
        return .init(systemName: "person")
    }
}

extension NSData {
    var asData: Data {
        return Data(referencing: self)
    }
}
