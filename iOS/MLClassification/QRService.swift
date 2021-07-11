//
//  MetaService.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 07/07/2021.
//

import UIKit
import AVFoundation

class QRService: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    static let updatedModelNotification = Notification.Name("updatedModelNotification")
    
    private var isPaused = false
    private weak var controller: UIViewController?
    private var loader: Loader?
    private var readData: [Int: String] = [:]
    
    init(_ controller: UIViewController) {
        self.controller = controller
        super.init()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if isPaused { return }
        guard let controller = controller else { return }
        guard let metaObject = metadataObjects.first else { return }
        guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return }
        guard let parts = readableObject.stringValue?.split(separator: ",") else { return }
        guard parts.count == 3 else { return }
        guard let part = Int(parts[0]) else { return }
        guard let total = Int(parts[1]) else { return }
        
        if loader == nil {
            isPaused = true
            readData = [:]
            DispatchQueue.main.async { [self] in
                loader = Loader(title: NSLocalizedString("scanning", comment: ""), cancelAction: { [weak self] _ in self?.loader = nil })
                loader?.present(on: controller, completion: { [weak self] in self?.isPaused = false })
            }
        }
        
        readData[part] = String(parts[2])
        DispatchQueue.main.async { [self] in
            let progress = Float(readData.count) / Float(total)
            loader?.update(progress)
        }
        
        if readData.count == total {
            isPaused = true
            let base64 = readData.sorted(by: { $0.key < $1.key}).map({ $0.value }).joined()
            let data = Data(base64Encoded: base64)
            try? data?.write(to: Delegate.modelUrl)
            NotificationCenter.default.post(name: QRService.updatedModelNotification, object: nil)
            DispatchQueue.main.async { [self] in
                loader?.dismiss { [weak self] in self?.loader = nil }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
                isPaused = false
            }
        }
    }
    
    
}
