//
//  String+Extension.swift
//  SwiftUIRickAndMorty
//
//  Created by Görkem Gür on 11.12.2024.
//

import Foundation

extension String {
    var asNSString: NSString {
        return NSString(string: self)
    }
}
