//
//  ViewController.swift
//  WMS001
//
//  Created by Tanmay Bakshi on 2017-01-16.
//  Copyright © 2017 Tanmay Bakshi. All rights reserved.
//

import UIKit
import AVFoundation
import ConversationV1
import SpeechToTextV1
import TextToSpeechV1

class ViewController: UIViewController {
    
    @IBOutlet var startStopButton: UIButton!
    @IBOutlet var conversationList: UITextView!
    
    var recorder: AVAudioRecorder!
    var player: AVAudioPlayer!
    
    var lastContext: Context?
    
    var size = ""
    var crustSize = ""
    var sauce = ""
    var topping1 = ""
    var topping2 = ""
    var topping3 = ""
    
    let outputFileURL = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! + "/watsonaudio.wav")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let session = AVAudioSession.sharedInstance()
        var settings = [String: AnyObject]()
        settings[AVSampleRateKey] = NSNumber(floatLiteral: 44100.0)
        settings[AVNumberOfChannelsKey] = NSNumber(integerLiteral: 1)
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try! recorder = AVAudioRecorder(url: outputFileURL, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()
    }
    
    @IBAction func startStopRecording() {
        if !recorder.isRecording {
            try! AVAudioSession.sharedInstance().setActive(true)
            recorder.record()
            startStopButton.setTitle("Stop", for: .normal)
        } else {
            recorder.stop()
            try! AVAudioSession.sharedInstance().setActive(false)
            let speechToText = SpeechToText(username: "", password: "")
            let settings = RecognitionSettings(contentType: .wav)
            speechToText.recognize(audio: outputFileURL, settings: settings, success: { (results) in
                OperationQueue.main.addOperation {
                    self.conversationList.text = self.conversationList.text + "You: " + results.bestTranscript + "\n"
                }
                let conversation = Conversation(username: "", password: "", version: "")
                let msgReq = MessageRequest(text: results.bestTranscript, alternateIntents: nil, context: self.lastContext, entities: nil, intents: nil, output: nil)
                conversation.message(withWorkspace: "", request: msgReq, failure: nil, success: { (response) in
                    self.lastContext = response.context
                    let responseEntity = response.entities.first
                    let responseIntent = response.intents.first
                    var toppingType: String?
                    if let entity = responseEntity {
                        let entityLabel = entity.entity
                        let entityValue = entity.value
                        if entityLabel == "topping" {
                            // "I'd like cheese as my first topping" topping_1 topping:cheese
                            // "I'd like my first topping" topping_1 ????
                            // "I'd like cheese" ???? topping:cheese
                            toppingType = entityValue.uppercased()
                        }
                    }
                    var logPizza = false
                    if let intent = responseIntent {
                        let contextualIntent = intent.intent
                        if contextualIntent == "size_small" {
                            // Small Pizza
                            self.size = "SMALL"
                        } else if contextualIntent == "size_medium" {
                            // Medium Pizza
                            self.size = "MEDIUM"
                        } else if contextualIntent == "size_large" {
                            // Large Pizza
                            self.size = "LARGE"
                        } else if contextualIntent == "crust_thin" {
                            // Thin Crust
                            self.crustSize = "THIN"
                        } else if contextualIntent == "crust_normal" {
                            // Normal Crust
                            self.crustSize = "NORMAL"
                        } else if contextualIntent == "crust_thick" {
                            // Thick Crust
                            self.crustSize = "THICK"
                        } else if contextualIntent == "sauce_none" {
                            // No Sauce
                            self.sauce = "NONE"
                        } else if contextualIntent == "sauce_easy" {
                            // Easy on the Sauce
                            self.sauce = "EASY"
                        } else if contextualIntent == "sauce_normal" {
                            // Normal Sauce
                            self.sauce = "NORMAL"
                        } else if contextualIntent == "sauce_extra" {
                            // Extra Sauce
                            self.sauce = "EXTRA"
                        } else if contextualIntent == "topping_1" {
                            // First Topping
                            self.topping1 = toppingType != nil ? toppingType! : self.topping1
                        } else if contextualIntent == "topping_2" {
                            // Second Topping
                            self.topping2 = toppingType != nil ? toppingType! : self.topping2
                        } else if contextualIntent == "topping_3" {
                            // Third Topping
                            self.topping3 = toppingType != nil ? toppingType! : self.topping3
                        } else if contextualIntent == "done" {
                            logPizza = true
                        }
                    }
                    OperationQueue.main.addOperation {
                        self.conversationList.text = self.conversationList.text + "Watson: " + response.output.text.first! + "\n"
                        if logPizza {
                            self.conversationList.text = self.conversationList.text + "Size: " + self.size + "\n"
                            self.conversationList.text = self.conversationList.text + "Crust: " + self.crustSize + "\n"
                            self.conversationList.text = self.conversationList.text + "Sauce: " + self.sauce + "\n"
                            self.conversationList.text = self.conversationList.text + "Topping 1: " + self.topping1 + "\n"
                            self.conversationList.text = self.conversationList.text + "Topping 2: " + self.topping2 + "\n"
                            self.conversationList.text = self.conversationList.text + "Topping 3: " + self.topping3 + "\n"
                        }
                        let textToSpeech = TextToSpeech(username: "", password: "")
                        textToSpeech.synthesize(response.output.text.first!, success: { (audio) in
                            try! AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                            self.player = try! AVAudioPlayer(data: audio)
                            self.player.prepareToPlay()
                            self.player.play()
                        })
                    }
                })
            })
            startStopButton.setTitle("Start", for: .normal)
        }
    }

}

