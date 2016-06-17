//
//  Hypotesis.swift
//  SSphinx
//
//  Created by mainvolume on 5/30/16.
//  Copyright © 2016 mainvolume. All rights reserved.
//

import Foundation

public struct Hypotesis {
    public let text: String
    public let score: Int
}

extension Hypotesis : CustomStringConvertible {
    
    public var description: String {
        get {
            return "Text: \(text) - Score: \(score)"
        }
    }
    
}

func +(lhs: Hypotesis, rhs: Hypotesis) -> Hypotesis {
    return Hypotesis(text: lhs.text + " " + rhs.text, score: (lhs.score + rhs.score) / 2)
}

func +(lhs: Hypotesis?, rhs: Hypotesis?) -> Hypotesis? {
    if let _lhs = lhs, let _rhs = rhs {
        return _lhs + _rhs
    } else {
        if let _lhs = lhs {
            return _lhs
        } else {
            return rhs
        }
    }
}