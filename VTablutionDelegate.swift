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
        let defaultFont = NSFont.systemFontOfSize(12.0)
        let defaultFontData: NSData = NSKeyedArchiver.archivedDataWithRootObject(defaultFont)
        let appDefaults = [
            "tabFont": defaultFontData
        ]
        NSUserDefaults.standardUserDefaults().registerDefaults(appDefaults)
        if let unwrappedViewController = viewController as VTabController? {
            unwrappedViewController.view.needsDisplay = true
            unwrappedViewController.tabView!.tabFont = defaultFont
        }
    }
    
    @IBAction public func showFontMenu(sender: AnyObject?) {
        let baseFontManager: NSFontManager = NSFontManager.sharedFontManager()
        
        if let fontPanel = baseFontManager.fontPanel(true) as NSFontPanel? {
            fontPanel.makeKeyAndOrderFront(sender)
        }
    }
}