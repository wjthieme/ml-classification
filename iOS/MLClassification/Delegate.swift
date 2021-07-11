//
//  AppDelegate.swift
//  MLClassification
//
//  Created by Wilhelm Thieme on 06/07/2021.
//

import UIKit
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import AppCenterDistribute

@main
class Delegate: UIResponder, UIApplicationDelegate {
    
    static let homeDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let modelUrl = homeDir.appendingPathComponent("model.tflite")

    internal var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppCenter.start(withAppSecret: "d6e99039-e8ed-4558-9a9c-f18d5f1f2fe1", services:[Analytics.self, Crashes.self, Distribute.self])
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            UserDefaults.standard.set("\(version) (\(build))", forKey: "appVersion")
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = Controller()
        window?.makeKeyAndVisible()
        
        return true
    }


}

