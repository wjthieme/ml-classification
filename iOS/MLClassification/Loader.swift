//
//  Loader.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 06/07/2021.
//

import UIKit

class Loader {
    
    private let alertController: UIAlertController
    private let progressIndicator = UIProgressView()
    
    init(title: String, cancelAction: ((UIAlertAction) -> Void)? = nil) {
        alertController = UIAlertController(title: title, message: "0%", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: cancelAction))
        progressIndicator.tintColor = UIColor(named: "Tint")
    }
    
    func present(on controller: UIViewController, completion: (() -> Void)? = nil) {
        controller.present(alertController, animated: true, completion: { [self] in
            progressIndicator.frame = CGRect(x: 8, y: 72.0, width: alertController.view.frame.width - 8*2 , height: 2)
            progressIndicator.progress = 0
            alertController.view.addSubview(progressIndicator)
            completion?()
        })
    }
    
    func dismiss(_ completion: (() -> Void)? = nil) {
        alertController.dismiss(animated: true, completion: completion)
    }
    
    func update(_ progress: Float) {
        let percentage = Int(progress * 100)
        alertController.message = "\(percentage)%"
        progressIndicator.progress = progress
    }
    
    func update(_ title: String) {
        alertController.title = title
    }
    
}
