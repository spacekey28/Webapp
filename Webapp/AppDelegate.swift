//
//  AppDelegate.swift
//  Aplestory
//
//  Created by woopadesign02 on 27/04/17.
//  Copyright © 2017 Crosswalk. All rights reserved.
//

import UIKit
import ReachabilitySwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var reachability: Reachability!
    var NCViewController: UIViewController!
    var RootViewController: UIViewController!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
        URLCache.shared = urlCache
        
        
        RootViewController = self.window?.rootViewController

        let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

        
        //declare this property where it won't go out of scope relative to your listener
        reachability = Reachability()!

        NCViewController = mainStoryboard.instantiateViewController(withIdentifier: "Noconnection") as UIViewController
        NCViewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        

        if !UserDefaults.standard.bool(forKey: "Walkthrough") {
            UserDefaults.standard.set(false, forKey: "Walkthrough")
        }
        
        return true
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        

        

        
        
        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async() {
                if reachability.isReachableViaWiFi {
                    print("Reachable via WiFi")
                } else {
                    print("Reachable via Cellular")
                }
                self.window?.rootViewController?.dismiss(animated: true, completion: nil)
                self.window?.rootViewController = self.RootViewController
            }
        }
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async() {
                print("Not reachable")
      
                self.window?.rootViewController?.present(self.NCViewController, animated: true, completion: nil)
                self.window?.makeKeyAndVisible()
                
            }
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        print("openURL \(url)")
        
        var urlString = url.absoluteString
        let queryArray = urlString.components(separatedBy: "//")
        
        var host:String = "http"
        if queryArray.count > 2 {
            host = queryArray[1]
            urlString = queryArray[2]
        } else {
            urlString = queryArray[1]
        }
        
        let parsedURLString:String? = "\(host)://\(urlString)"
        if parsedURLString != nil {
            UserDefaults.standard.set(parsedURLString, forKey: "URL")
        }
        
        return true
    }

    /// set orientations you want to be allowed in this property by default
    /*var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }*/
    

}
