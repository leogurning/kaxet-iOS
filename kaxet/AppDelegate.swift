//
//  AppDelegate.swift
//  kaxet
//
//  Created by LEONARD GURNING on 16/07/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import CoreData
import SwiftKeychainWrapper
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //If it's first run after installation/re-installation, remove all keychain key
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: "FirstRun") == false {
            
            // remove keychain items here
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Token)
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Userid)
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Username)
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Name)
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Usertype)
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.Fblogin)
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.Keychains.UserPhoto)
            
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.PaymentMtd.Pulsa)
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.PaymentMtd.Gopay)
            KeychainWrapper.standard.removeObject(forKey: APPCONSTANT.PaymentMtd.Cash)
            FBSDKLoginManager().logOut()
            
            // update the flag indicator
            userDefaults.set(true, forKey: "FirstRun")
            userDefaults.synchronize() // forces the app to update the NSUserDefaults

        }
        
        let accessToken: String? = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)
        
        if accessToken != nil {
            let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let homePage = mainStoryBoard.instantiateViewController(withIdentifier: "StartViewController") as! StartViewController
            //homePage.hidesBottomBarWhenPushed = true
            self.window?.rootViewController = homePage

        }
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: (options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String), annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        // Add any custom logic here.
        return handled;
        
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        
        DownloadService.shared.backgroundSessionCompletionHandler = completionHandler
        
        let config = URLSessionConfiguration.background(withIdentifier: identifier)
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        let session = URLSession(configuration: config, delegate: DownloadService.shared as? URLSessionDelegate, delegateQueue: OperationQueue.main)
        
        /*
        let session = DownloadService.shared.session
        */
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            
            // downloadTasks = [URLSessionDownloadTask]
            print("There are \(downloadTasks.count) download tasks associated with this session.")
            for downloadTask in downloadTasks {
                print("downloadTask.taskIdentifier = \(downloadTask.taskIdentifier)")
            }
        }
 
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "kaxet")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

