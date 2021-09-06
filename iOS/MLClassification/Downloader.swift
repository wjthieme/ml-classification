//
//  Downloader.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 21/07/2021.
//

import Foundation
import var CommonCrypto.CC_SHA1_DIGEST_LENGTH
import func CommonCrypto.CC_SHA1
import typealias CommonCrypto.CC_LONG

class Downloader {
    
    static func download(id: String, hash: String, completion: @escaping ((Error?) -> Void)) {
        let url = id == "test" ? Delegate.testModel : Delegate.baseUrl.appendingPathComponent(id)
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            do {
                guard let response = response as? HTTPURLResponse else { throw URLError(.cannotParseResponse) }
                guard (200..<300).contains(response.statusCode) else { throw URLError(.badServerResponse) }
                guard let data = data else { throw URLError(.zeroByteResource) }
                guard sha1(data) == hash else { throw URLError(.secureConnectionFailed) }
                try data.write(to: Delegate.modelUrl)
                completion(nil)
            } catch {
                completion(error)
            }
        }.resume()
    }
    
    private static func sha1(_ data: Data) -> String {
        let length = Int(CC_SHA1_DIGEST_LENGTH)
        var digest = Data(count: length)

        _ = digest.withUnsafeMutableBytes { digestBytes -> UInt8 in
            data.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(data.count)
                    CC_SHA1(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
}
