//
//  ThinkingBrain.swift
//  EgyptianSphinx
//
//  Created by mainvolume on 6/17/16.
//  Copyright © 2016 mainvolume. All rights reserved.
//

import Foundation
import GameplayKit

public protocol BrainEntityReactor:class {
    
    func newThoughtArised(aThought:NSString, score:Int)
    func newReationArised(aReaction:NSString, score:Int)
}



public class ThinkingBrain: NSObject {
    
    var thinkingBrainEngine:Decoder!
    var config:Config!
    var hmm:String!
    var lm:String!
    var dict:String!

    
    
    private let bgQue = dispatch_queue_create(
        "bøb.bg", DISPATCH_QUEUE_CONCURRENT)
    
    public weak var reactor:BrainEntityReactor!
    
    
    public override init() {
        super.init()
       
        self.createBrain()
    }
    
    
    private func createBrain() {
        autoreleasepool {
            [unowned self] in
            dispatch_async(self.bgQue) {
                [unowned self] in
                
                print("Brain")
                let modelPath =  NSBundle.mainBundle().pathForResource("en-us", ofType: nil)
                
                self.hmm = (modelPath! as NSString).stringByAppendingPathComponent("en-us")
                self.lm = (modelPath! as NSString).stringByAppendingPathComponent("en-us.lm.dmp")
                self.dict = (modelPath! as NSString).stringByAppendingPathComponent("cmudict-en-us.dict")
                self.config = Config(args: ("-hmm", self.hmm), ("-lm", self.lm), ("-dict", self.dict))
                
                self.config?.showDebugInfo = false
                //self.redirectConsoleLogToDocumentFolder()
                self.thinkingBrainEngine = Decoder(config:self.config!)
                self.thinkingBrainEngine!.startDecodingSpeech {
                    [unowned self] in
                    if let hyp: Hypotesis = $0 {
                        self.processOutput(hyp)
                    }
                }
            }
        }
        
    }
    
    public func sleep () {
        
        
        dispatch_async(self.bgQue) {
            [unowned self] in
            let x = self.thinkingBrainEngine?.shouldProcess
            if x != nil {
                self.thinkingBrainEngine!.shouldListen = false
                print("Brain Disolved")
            }
        }
    }
    public func listen() {
        
        
            dispatch_async(self.bgQue) {
                [unowned self] in
                let x = self.thinkingBrainEngine?.shouldProcess
                if x != nil {
                    self.thinkingBrainEngine!.shouldListen = true
                    print("Brain Disolved")
                }
            }
        
    }
    
    private func processOutput(hyp:Hypotesis) {
        print("Text: \(hyp.text) - Score: \(hyp.score)")
        let outputString:NSString = hyp.text ?? ""
        
        if outputString.length > 1 {
            var added:String
            let ø = GKRandomSource.sharedRandom().nextIntWithUpperBound(7)
            switch ø {
            case 1:
                added = "?"
            case 2:
                added = "."
            case 3:
                added = "!"
            default:
                added = "."
            }
            
            
            let outPutTerminated = outputString.stringByAppendingString(added)
            
            dispatch_async(dispatch_get_main_queue(), {
                [unowned self] in
                if let thought = self.reactor {
                    thought.newThoughtArised(outPutTerminated, score: hyp.score)
                }
                })
            
        } else {
            
            let outPutTerminated = outputString
            dispatch_async(dispatch_get_main_queue(), {
                [unowned self] in
                if let reaction = self.reactor {
                    reaction.newReationArised(outPutTerminated,score: hyp.score)
                }
            })
            
        }
        
        
    }
    
    
    
    deinit {
        self.dict = nil
        self.config = nil
        self.lm = nil
        self.thinkingBrainEngine = nil
        print("DEINITTING SPHINX")
    }
}
