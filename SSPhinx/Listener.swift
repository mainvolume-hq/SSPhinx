//
//  SSReader.swift
//  SSphinx
//
//  Created by Ø on 26/08/16.
//  Copyright © 2016 Bruno Berisso. All rights reserved.
//

import Foundation


class Listener {
    var d:Decoder?
    var onHyp: ((result: Hypotesis)->())? //an optional function
    
    init() {
        
        let modelPath =  NSBundle.mainBundle().pathForResource("en-us", ofType: nil)!
        
        let hmm = (modelPath as NSString).stringByAppendingPathComponent("en-us")
        let lm = (modelPath as NSString).stringByAppendingPathComponent("en-us.lm.dmp")
        let dict = (modelPath as NSString).stringByAppendingPathComponent("cmudict-en-us.dict")
        
        if let config = Config(args: ("-hmm", hmm), ("-lm", lm), ("-dict", dict)) {
            config.showDebugInfo = false
            self.d = Decoder(config:config)
        } else {
            print("Can't access pocketsphinx model. Bundle root: \(NSBundle.mainBundle())")
        }
        
    }
    
    func listen() {
        
        self.d?.startDecodingSpeech {
            [unowned self](hyp) -> () in
            if hyp != nil {
                self.onHyp?(result: hyp!)
            }
        }
    }
    
    
    func stopListening() {
        self.d?.stopDecodingSpeech()
    }
    
    
    
    deinit {
        print("Stopped Reader")
    }
    
}
