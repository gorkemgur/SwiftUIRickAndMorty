//
//  UIIMage+Extension.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation
import UIKit

extension UIImage {
    var asData: Data? {
        return self.jpegData(compressionQuality: 1.0)
    }
}
