//
//  UndoManagerClosures.swift
//  tablution
//
//  Created by Ian McCowan on 11/27/15.
//
//

import Foundation

extension NSUndoManager { 
    /// Use the return value if you later need to remove this action with NSUndoManager#removeAllActionsWithTarget(). 
    func registerAction(actionClosure: Void -> Void) -> ClosureAction { 
        let action = ClosureAction(closure: actionClosure) 
        self.registerUndoWithTarget(action, selector: "perform:", object: nil) 
        return action 
    } 
    
    class ClosureAction: NSObject { 
        let closure: Void -> Void 
        
        init(closure: Void -> Void) { 
            self.closure = closure 
        } 
        
        func perform(unused: AnyObject?) { 
            closure() 
        } 
    } 
}