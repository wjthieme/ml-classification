//
//  BufferService.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 07/07/2021.
//

import UIKit
import AVFoundation
import TensorFlowLite

class MLService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var model: Interpreter?
    private weak var controller: Controller?
    private var updating = false
    
    init(_ controller: Controller) {
        self.controller = controller
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(tryLoadModel), name: QRService.updatedModelNotification, object: nil)
        tryLoadModel()
    }
    
    @objc private func tryLoadModel() {
        updating = true
        model = try? Interpreter(modelPath: Delegate.modelUrl.path)
        try? model?.allocateTensors()
        updating = false
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        do {
            if updating { throw CocoaError(.userCancelled) }
            guard let model = model else { throw CocoaError(.fileNoSuchFile) }
            guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { throw CocoaError(.coderReadCorrupt) }
            let size = try model.input(at: 0)
            
            let input = CIImage(cvPixelBuffer: buffer)
                .oriented(.right)
                .cropped()
                .resize(to: CGSize(width: size.shape.dimensions[1], height: size.shape.dimensions[1]))
            
            try model.copy(input.toBitmap(), toInputAt: 0)
            try model.invoke()
            let output = try model.output(at: 0).data
            
            let floats = [Float](unsafeData: output)!
            let max = floats.enumerated().max(by: { $0.element < $1.element })!
            
            DispatchQueue.main.async { [self] in
                controller?.predictionLabel?.isHidden = false
                let pred = NSLocalizedString(max.offset == 0 ? "face" : "noFace", comment: "")
                let prob = Int(max.element * 100)
                controller?.predictionLabel?.text = "\(pred) (\(prob)%)"
            }
            
        } catch {
            DispatchQueue.main.async { [self] in
                controller?.predictionLabel?.isHidden = true
            }
        }
        
    }
}

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
