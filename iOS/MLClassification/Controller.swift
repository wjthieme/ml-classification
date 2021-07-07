//
//  ViewController.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 06/07/2021.
//

import UIKit
import AVFoundation

fileprivate let metaQueue = DispatchQueue(label: "metaQueue")

class Controller: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isCapturesSessionBuilt = false
    
    private var loader: Loader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private func buildCaptureSession() {
        defer { captureSession?.startRunning() }
        if isCapturesSessionBuilt { return }
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: .back)
        guard let captureDevice = discoverySession.devices.first else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        try? captureDevice.lockForConfiguration()
        
        captureDevice.focusMode = .autoFocus
        captureDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        captureSession?.addInput(input)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.insertSublayer(previewLayer!, at: 0)
        
        let metaOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(metaOutput)
        metaOutput.setMetadataObjectsDelegate(self, queue: metaQueue)
        metaOutput.metadataObjectTypes = [.qr]
        
        
        //            let bufferOutput = AVCaptureVideoDataOutput()
        //            bufferOutput.setSampleBufferDelegate(self, queue: videoQueue)
        //            bufferOutput.alwaysDiscardsLateVideoFrames = true
        
//        captureSession?.addOutput(bufferOutput)
        
        captureSession?.commitConfiguration()
        
        setFocalPoint()
        
        isCapturesSessionBuilt = true
    }
    
    private func setFocalPoint() {
        guard let input = self.captureSession?.inputs.first as? AVCaptureDeviceInput else { return }
        let device = input.device
        do { try device.lockForConfiguration() } catch { return }
        device.focusMode = .continuousAutoFocus
        device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
        device.unlockForConfiguration()
    }
    
    
    @objc private func shouldBuildCaptureSession() {
        AVCaptureDevice.requestAccess(for: .video) { response in
            DispatchQueue.main.async { response ? self.buildCaptureSession() : self.showAuthorizationAlert() }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldBuildCaptureSession()
        NotificationCenter.default.addObserver(self, selector: #selector(shouldBuildCaptureSession), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession?.stopRunning()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func showAuthorizationAlert() {
        let alert = UIAlertController(title: nil, message: NSLocalizedString("cameraAuthrorisationAlertMessage", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    
    private var readData: [Int: String] = [:]
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metaObject = metadataObjects.first else { return }
        guard let readableObject = metaObject as? AVMetadataMachineReadableCodeObject else { return }
        guard let parts = readableObject.stringValue?.split(separator: ",") else { return }
        guard parts.count == 3 else { return }
        guard let part = Int(parts[0]) else { return }
        guard let total = Int(parts[1]) else { return }
        
        readData[part] = String(parts[2])
        DispatchQueue.main.async { [self] in
            if loader == nil {
                loader = Loader(title: "Scanning", cancelAction: { [weak self] _ in self?.loader = nil })
                loader?.present(on: self)
                readData = [:]
            }
            
            let progress = Float(readData.count) / Float(total)
            loader?.update(progress)
        }
        
        if readData.count == total {
            let base64 = readData.values.joined()
            let data = Data(base64Encoded: base64)
            DispatchQueue.main.async { [self] in
                loader?.dismiss { [weak self] in self?.loader = nil }
            }
            
        }
        
    }
    
}

