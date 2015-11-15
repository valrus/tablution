//
//  HandyTools.swift
//  tablution
//
//  Created by Ian McCowan on 11/1/15.
//
//

import Foundation

func sandwich<T: Comparable>(lower lower: T, num: T, upper: T) -> T {
    return (num < lower ? lower : (num > upper ? upper : num))
}