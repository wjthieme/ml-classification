//
//  Constants.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 07/07/2021.
//

import Foundation

class Constants {
    static let metaQueue = DispatchQueue(label: "metaQueue")
    static let bufferQueue = DispatchQueue(label: "bufferQueue")
    static let homeDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let modelUrl = homeDir.appendingPathComponent("model.tflite")
}
