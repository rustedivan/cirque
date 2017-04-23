//
//  AppDelegate.swift
//  cirque
//
//  Created by Ivan Milles on 26/10/14.
//  Copyright (c) 2014 Rusted. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	static let HistoryFilename = "game-trail-history.trails"
	static let UserFilename = "game-user-profile.profile"
	
	var window: UIWindow?
	var historyWriter = TrailHistory(filename: AppDelegate.HistoryFilename)
	var userProfile = UserProfile()

	class var appSaveDir: String {
		get {
			let appSupportDir = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)[0]
			let bundleId = Bundle.main.bundleIdentifier
			return appSupportDir + "/" + bundleId! + "/"
		}
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		print("Loading starting trends from \(historyWriter.saveTimestamp):")
		historyWriter.dumpTrends()
		
		if let loadedProfile = (NSKeyedUnarchiver.unarchiveObject(withFile: AppDelegate.appSaveDir + AppDelegate.UserFilename) as? UserProfile) {
			userProfile = loadedProfile
			print("Loading user profile with E=\(userProfile.effortPoints), F=\(userProfile.skillPoints)")
		}
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		print("Saving current trends:")
		historyWriter.dumpTrends()
		historyWriter.save()
		let saved = NSKeyedArchiver.archiveRootObject(userProfile, toFile: AppDelegate.appSaveDir + AppDelegate.UserFilename)
		print("Saving user points: \(saved ? "√" : "x")")
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

