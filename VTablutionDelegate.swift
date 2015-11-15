//
//  VTablutionDelegate.swift
//  tablution
//
//  Created by Ian McCowan on 11/15/15.
//
//

import Foundation

@objc public class VTablutionDelegate: NSObject, NSApplicationDelegate {
    var viewController: VTabController?
    
    public func applicationDidFinishLaunching(notification: NSNotification) {
        let defaultFontData: NSData = NSKeyedArchiver.archivedDataWithRootObject(NSFont.systemFontOfSize(12.0))
        let appDefaults = [
            "tabFont": defaultFontData
        ]
        NSUserDefaults.standardUserDefaults().registerDefaults(appDefaults)
        if let unwrappedViewController = viewController as VTabController? {
            unwrappedViewController.view.needsDisplay = true
        }
    }
}