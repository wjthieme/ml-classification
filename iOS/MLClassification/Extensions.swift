//
//  Extensions.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 07/07/2021.
//

import CoreImage

extension CIImage {
    func cropped(to aspect: CGFloat = 1) -> CIImage {
        let width = min(extent.width, extent.height/aspect)
        let height = min(extent.height, extent.width*aspect)
        let x = extent.width*0.5 - width*0.5
        let y = extent.height*0.5 - height*0.5
        return cropped(to: CGRect(x: x, y: y, width: width, height: height)).transformed(by: .init(translationX: -x, y: -y))
    }
    
    func resize(to size: CGSize) -> CIImage {
        let xScale = size.width / extent.width
        let yScale = size.height / extent.height
        return transformed(by: .init(scaleX: xScale, y: yScale))
    }
    
    func toBitmap(isBGR: Bool = false) -> Data {
        let bytesPerRow = Int(extent.width * 4)
        var rgba = [UInt8](repeating: 0, count: Int(extent.width * extent.height) * 4)
        CIContext().render(
            self,
            toBitmap: &rgba,
            rowBytes: bytesPerRow,
            bounds: extent,
            format: isBGR ? CIFormat.BGRA8 : CIFormat.RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB())
        
        var rgb = [Float](repeating: 0, count: Int(extent.width * extent.height) * 3)
        var index = 0
        for comp in rgba.enumerated() {
            if comp.offset % 4 == 3 { continue }
            rgb[index] = Float32(comp.element) / 255
            index += 1
        }
        return rgb.withUnsafeBufferPointer(Data.init(buffer:))
    }
}

extension Array {
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0
        else {
            return nil
        }
        
        self = unsafeData.withUnsafeBytes({ (pointer) in
            return .init(pointer.bindMemory(to: Element.self))
        })
    }
}
