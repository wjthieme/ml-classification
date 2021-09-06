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
    
    private static let appCenterClientId = "d6e99039-e8ed-4558-9a9c-f18d5f1f2fe1"
    private static let homeDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let modelUrl = homeDir.appendingPathComponent("model.tflite")
    static let baseUrl = URL(string: "https://a.tmp.ninja/")!
    static let testModel = URL(string: "https://github.com/wjthieme/ml-classification/blob/main/model.tflite?raw=true")!

    internal var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppCenter.start(withAppSecret: Delegate.appCenterClientId, services: [Analytics.self, Crashes.self, Distribute.self])
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            UserDefaults.standard.set("\(version) (\(build))", forKey: "appVersion")
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = Controller()
        window?.makeKeyAndVisible()
        
        return true
    }
    
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        guard url.host == "model" else { return false }
        guard let controller = window?.rootViewController as? Controller else { return false }
        guard let service = controller.qrService else { return false }
        service.didFind(url: url)
        return true
    }

}

