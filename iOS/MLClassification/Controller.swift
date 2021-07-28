//
//  ViewController.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 06/07/2021.
//

import UIKit
import AVFoundation

class Controller: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
    
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isCapturesSessionBuilt = false
    
    var qrService: QRService?
    var mlService: MLService?
    
    private var cameraPosition = AVCaptureDevice.Position.back
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "Layout", bundle: nil)
        qrService = QRService(self)
        mlService = MLService(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(shouldBuildCaptureSession), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func buildCaptureSession() {
        defer { captureSession?.startRunning() }
        if isCapturesSessionBuilt { return }
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInTripleCamera, .builtInDualCamera, .builtInWideAngleCamera], mediaType: .video, position: cameraPosition)
        guard let captureDevice = discoverySession.devices.first else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        captureSession?.addInput(input)
        
        previewLayer?.removeFromSuperlayer()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.insertSublayer(previewLayer!, at: 0)
        
        let metaOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(metaOutput)
        metaOutput.setMetadataObjectsDelegate(qrService, queue: DispatchQueue.global())
        metaOutput.metadataObjectTypes = [.qr]
        
        let bufferOutput = AVCaptureVideoDataOutput()
        captureSession?.addOutput(bufferOutput)
        bufferOutput.setSampleBufferDelegate(mlService, queue: DispatchQueue.global())
        bufferOutput.alwaysDiscardsLateVideoFrames = true
        
        captureSession?.commitConfiguration()
        setFocalPoint()
        isCapturesSessionBuilt = true
        captureDevice.unlockForConfiguration()
    }
    
    private func setFocalPoint() {
        guard cameraPosition == .back else { return }
        guard let input = self.captureSession?.inputs.first as? AVCaptureDeviceInput else { return }
        do { try input.device.lockForConfiguration() } catch { return }
        input.device.focusMode = .continuousAutoFocus
        input.device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
        input.device.unlockForConfiguration()
    }
    
    
    @objc private func shouldBuildCaptureSession() {
        AVCaptureDevice.requestAccess(for: .video) { response in
            DispatchQueue.main.async { response ? self.buildCaptureSession() : self.showAuthorizationAlert() }
        }
    }
    
    @IBAction private func didPressSwitchButton() {
        cameraPosition = cameraPosition == .back ? .front : .back
        captureSession?.stopRunning()
        isCapturesSessionBuilt = false
        let animation: UIView.AnimationOptions = cameraPosition == .back ? .transitionFlipFromLeft : .transitionFlipFromRight
        UIView.transition(with: view, duration: 0.5, options: [.curveEaseInOut, animation], animations: nil, completion: nil)
        shouldBuildCaptureSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        shouldBuildCaptureSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureSession?.stopRunning()
    }
    
    private func showAuthorizationAlert() {
        let alert = UIAlertController(title: nil, message: NSLocalizedString("cameraAuthrorisation", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
}

