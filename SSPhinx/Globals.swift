//
//  NSFileHandle+Extension.swift
//  SSphinx
//
//  Created by mainvolume on 5/30/16.
//  Copyright © 2016 mainvolume. All rights reserved.
//

import Foundation

let STrue: CInt = 1
let SFalse: CInt = 0

extension NSFileHandle {
    
    func reduceChunks<T>(size: Int, initial: T, reducer: (NSData, T) -> T) -> T {
        
        var reduceValue = initial
        var chuckData = readDataOfLength(size)
        
        while chuckData.length > 0 {
            reduceValue = reducer(chuckData, reduceValue)
            chuckData = readDataOfLength(size)
        }
        
        return reduceValue
    }
    
}
