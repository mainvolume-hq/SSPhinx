//
//  Decoder.swift
//  SSphinx
//
//  Created by mainvolume on 5/30/16.
//  Copyright © 2016 mainvolume. All rights reserved.
//

import Foundation
import AVFoundation
import Sphinxing



private enum SpeechStateEnum : CustomStringConvertible {
    case Silence
    case Speech
    case Utterance
    
    var description: String {
        get {
            switch(self) {
            case .Silence:
                return "Silence"
            case .Speech:
                return "Speech"
            case .Utterance:
                return "Utterance"
            }
        }
    }
}

public class Decoder:NSObject {
    
    private var psDecoder: COpaquePointer
    private var speechState: SpeechStateEnum
    
    public var bufferSize: Int = 2048

    public var shouldProcess = false
    public var shouldListen = false
    public init?(config: Config) {
 
        speechState = .Silence
        
        if config.cmdLnConf != nil{
            psDecoder = ps_init(config.cmdLnConf)
            
            if psDecoder == nil {
                return nil
            }
        } else {
            psDecoder = nil
            return nil
        }
        
        
    }
    
    deinit {
        self.stopListening()
        self.shouldProcess = false
        print("Releasing Decoder")
        let refCount = ps_free(psDecoder)
        assert(refCount == 0, "Can't free decoder, it's shared among instances")
    }
    
    private func process_raw(data: NSData) -> CInt {
        //Sphinx expect words of 2 bytes but the NSFileHandle read one byte at time so the lenght of the data for sphinx is the half of the real one.
        
        let dataLenght = data.length / 2
        let numberOfFrames = ps_process_raw(psDecoder, UnsafePointer(data.bytes), dataLenght, 0, 0)
        let hasSpeech = in_sppech()
        
        switch (speechState) {
        case .Silence where hasSpeech:
            speechState = .Speech
        case .Speech where !hasSpeech:
            speechState = .Utterance
        case .Utterance where !hasSpeech:
            speechState = .Silence
        default:
            break
        }
        
        return numberOfFrames
    }
    
    private func in_sppech() -> Bool {
        return ps_get_in_speech(psDecoder) == 1
    }
    
    private func start_utt() -> Bool {
        return ps_start_utt(psDecoder) == 0
    }
    
    private func end_utt() -> Bool {
        return ps_end_utt(psDecoder) == 0
    }
    
    private func get_hyp() -> Hypotesis? {
        var score: CInt = 0
        let string: UnsafePointer<CChar> = ps_get_hyp(psDecoder, &score)
        
        if let text = String.fromCString(string) {
            print(text)
            return Hypotesis(text: text, score: Int(score))
        } else {
            return nil
        }
    }
    
    
    
    var timer: NSTimer!
    
    
    func toNSData(PCMBuffer: AVAudioPCMBuffer) -> NSData {
        
        let channelCount = 1  // given PCMBuffer channel count is 1
        let channels = UnsafeBufferPointer(start: PCMBuffer.int16ChannelData, count: channelCount)
        let ch0Data = NSData(bytes: channels[0], length:Int(PCMBuffer.frameCapacity * PCMBuffer.format.streamDescription.memory.mBytesPerFrame))
        return ch0Data
    }
    
    
    
    //
    var engine = AVAudioEngine()
    var audioBuffer = AVAudioPCMBuffer()
    
    
    
    func stopListening() {
        self.shouldListen = false
        self.end_utt()
    }
    
    
    public func disolve () {
        
        engine.stop()
        engine.mainMixerNode.removeTapOnBus(0)
                print("-----------------------------------------Freeing stuff")
    }
    
    
    public func startDecodingSpeech ( utteranceComplete:  (Hypotesis?) -> ()) {
        
        autoreleasepool {
            [unowned self] in
            self.shouldProcess = true
            self.engine.stop()
            self.engine.reset()
            self.engine = AVAudioEngine()
            
            let input = self.engine.inputNode!
            let formatIn = AVAudioFormat(commonFormat: .PCMFormatInt16, sampleRate: 44100, channels: 1, interleaved: false)
            self.engine.connect(input, to: self.engine.outputNode, format: formatIn)
            
            assert(self.engine.inputNode != nil)
            
            input.installTapOnBus(0, bufferSize: 4096, format: formatIn, block:
                {[unowned self] (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    
                    let data = self.toNSData(buffer)
                    if data.length > 0 {
                        if self.shouldProcess && self.shouldListen{
                            self.process_raw(data)
                            if self.speechState == .Utterance {
                                self.end_utt()
                                utteranceComplete(self.get_hyp())
                                self.start_utt()
                            }
                        }
                    }
                })
            
            self.engine.mainMixerNode.outputVolume = 0.0
            self.start_utt()
            self.engine.prepare()
            try! self.engine.start()
         
            
        }
    }
    
    
}