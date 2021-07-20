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
    private weak var controller: Controller?
    
    init(_ controller: Controller) {
        self.controller = controller
        super.init()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metaObject = metadataObjects.first else { return }
        guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return }
        guard let url = URL(string: readableObject.stringValue ?? "") else { return }
        didFind(url: url)
    }
    
    func didFind(url: URL) {
        let downloadPath = url.absoluteString.replacingOccurrences(of: "ml-classification://", with: "")
        if isPaused { return }
        guard let downloadUrl = URL(string: downloadPath) else { return }
        isPaused = true
        startLoading()
        URLSession.shared.dataTask(with: downloadUrl) { [self] data, response, error in
            do {
                guard let data = data else { throw CocoaError.init(.fileWriteUnknown) }
                try data.write(to: Delegate.modelUrl)
                NotificationCenter.default.post(name: QRService.updatedModelNotification, object: nil)
            } catch {
                didError(error)
            }
            stopLoading()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
                isPaused = false
            }
        }.resume()
    }
    
    
    private func startLoading() {
        guard Thread.isMainThread else { DispatchQueue.main.async { self.startLoading() }; return }
        guard let controller = controller else { return }
        controller.activityIndicator.startAnimating()
        controller.activityIndicator.alpha = 0
        UIView.animate(withDuration: 0.3) {
            controller.activityIndicator.alpha = 1
        }
    }
    
    private func stopLoading() {
        guard Thread.isMainThread else { DispatchQueue.main.async { self.stopLoading() }; return }
        guard let controller = controller else { return }
        controller.activityIndicator.alpha = 1
        UIView.animate(withDuration: 0.3, animations: {
            controller.activityIndicator.alpha = 0
        }) { _ in
            controller.activityIndicator.stopAnimating()
        }
    }
    
    private func didError(_ error: Error) {
        guard Thread.isMainThread else { DispatchQueue.main.async { self.didError(error) }; return }
        guard let controller = controller else { return }
        let alert = UIAlertController(title: NSLocalizedString("downloadError", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}
