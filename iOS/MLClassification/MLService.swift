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
    private weak var predictionLabel: UIButton?
    
    init(_ label: UIButton) {
        self.predictionLabel = label
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(tryLoadModel), name: QRService.updatedModelNotification, object: nil)
        tryLoadModel()
    }
    
    @objc private func tryLoadModel() {
        model = try? Interpreter(modelPath: Delegate.modelUrl.path)
        try? model?.allocateTensors()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        do {
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
                predictionLabel?.isHidden = false
                let pred = max.offset == 0 ? "Yes" : "No"
                let prob = Int(max.element * 100)
                predictionLabel?.setTitle("\(pred) (\(prob)%)", for: .normal)
            }
            
        } catch {
            DispatchQueue.main.async { [self] in
                predictionLabel?.isHidden = true
            }
        }
        
    }
}


