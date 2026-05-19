//
//  DGCRTCWeakDelegates.swift
//  ManGo
//
//  Created by mango-linwieyan on 2024/3/21.
//

import Foundation

/// 弱引用代理集合
class DGCRTCWeakDelegates<T : AnyObject> {
    //代理
    let delegates = NSHashTable<T>(options: .weakMemory)
    
    var allObjects: Array<T> {
        get{
            self.delegates.allObjects
        }
    }
    
    func addDelegate(_ delegate : T) {
        self.delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate : T) {
        if self.delegates.contains(delegate) {
            self.delegates.remove(delegate)
        }
    }
    
    func clear() {
        self.delegates.removeAllObjects()
    }
}
