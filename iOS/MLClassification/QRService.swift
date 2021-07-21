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
        if isPaused { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        guard let queryItems = components.queryItems else { return }
        guard let id = queryItems.first(where: { $0.name == "id" })?.value else { return }
        guard let hash = queryItems.first(where: { $0.name == "hash" })?.value else { return }
        
        isPaused = true
        startLoading()
        Downloader.download(id: id, hash: hash) { [self] error in
            if let error = error {
                didError(error)
            } else {
                NotificationCenter.default.post(name: QRService.updatedModelNotification, object: nil)
            }
            stopLoading()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
                isPaused = false
            }
        }
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
