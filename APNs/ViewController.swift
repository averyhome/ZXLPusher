//
//  ViewController.swift
//  APNs
//
//  Created by Sven on 2020/4/23.
//  Copyright © 2020 zhuxiaoliang. All rights reserved.
//

import Cocoa
import APNSwift
import Logging
import NIO
import NIOSSL
import NIOHTTP2
import RxSwift
import RxCocoa
import SwifterSwift

class ViewController: NSViewController {
    
    let bag = DisposeBag()
    
    var p8Buffer: ByteBuffer?
    
    @IBOutlet weak var sendButton: NSButton!
    
    @IBOutlet weak var fileButton: NSButton!
    
    @IBOutlet weak var keyIDTF: NSTextField!
    
    @IBOutlet weak var TeamIDTF: NSTextField!

    @IBOutlet weak var envSegument: NSSegmentedControl!
    //topicID
    @IBOutlet weak var bundleIdTF: NSTextField!
    
    @IBOutlet weak var deviceTokenTF: NSTextField!
    
    @IBOutlet weak var payloadTextView: NSTextView!
    
    @IBOutlet weak var LogTextView: NSTextView!
    
    @IBOutlet weak var logScrollView: NSScrollView!
    
    
    private var keyID = ""
    private var teamID = ""
    private var bundleID = ""
    private var deviceToken = ""
    
    struct BasicNotification: APNSwiftNotification {
        let aps: APNSwiftPayload
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        envSegument.selectedSegment = 0
        
//        UserDefaults.standard.dictionaryRepresentation().forEach { (val) in
//            UserDefaults.standard.removeObject(forKey: val.key)
//        }
        
        fileButton.image = NSImage(named: "upload")?.scaled(toMaxSize: CGSize.init(width: 30, height: 30))
        fileButton.imageScaling = .scaleProportionallyUpOrDown
        
        payloadTextView.backgroundColor = .clear
        LogTextView.backgroundColor = .clear
        
        
        
        if let data = UserDefaults.standard.lastP8Data {
            var mutableByteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
            mutableByteBuffer.writeBytes(data)
            self.p8Buffer = mutableByteBuffer
            self.fileButton.title = UserDefaults.standard.lastP8Path ?? "请选择.p8 AuthKey"
            fileButton.image = NSImage(named: "file")?.scaled(toMaxSize: CGSize.init(width: 60, height: 60))
        }
        
        
        
        fileButton.rx.tap.subscribe(onNext: { (_) in
            let panel = NSOpenPanel()
            panel.prompt = "open"
            panel.allowedFileTypes = ["p8"]
            panel.directoryURL = nil
            panel.beginSheetModal(for: NSApplication.shared.keyWindow!) {[weak self] (res) in
                guard res.rawValue == 1 else {
                    return ()
                }
                
                let fileUrl = panel.urls.first!
                guard let fileHandle = try? FileHandle.init(forReadingFrom: fileUrl) else {
                    return ()
                }
                let data = fileHandle.readDataToEndOfFile()
                var mutableByteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
                mutableByteBuffer.writeBytes(data)
                
                UserDefaults.standard.lastP8Data = data
                UserDefaults.standard.lastP8Path = fileUrl.path
                self?.fileButton.title = fileUrl.path
            
                _ = String.init(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)
                
                self?.p8Buffer = mutableByteBuffer
                
                self?.fileButton.image = NSImage(named: "file")?.scaled(toMaxSize: CGSize.init(width: 30, height: 30))
            }
        }).disposed(by: bag)
        
        sendButton.rx.tap.subscribe(onNext: {[weak self] (_) in
            DispatchQueue.global().async {
                self?.sendPush()
            }
            
        }).disposed(by: bag)
        
        payloadTextView.font = NSFont.systemFont(ofSize: 20)
        payloadTextView.isAutomaticQuoteSubstitutionEnabled = false
        
        LogTextView.font = NSFont.systemFont(ofSize: 20)
        LogTextView.isAutomaticQuoteSubstitutionEnabled = false
        logScrollView.verticalScrollElasticity = .allowed
        
        let payLoadStr = """
            {"aps":{"content-available":0,"alert":{"title":"Hello world","subtitle":"gayhub.com","body":"welcome to gay hub"},"mutable-content":0,"sound":"default","badge":1},"key1":"value1","key2":{}}
        """
        payloadTextView.textStorage?.append(NSAttributedString.init(string: payLoadStr.toDic()?.jsonString(prettify: true) ?? "", attributes: [.font: NSFont.systemFont(ofSize: 18),.foregroundColor: NSColor(hexString: "666666")]))
        
        keyID = "BHZKRG2668"
        teamID = "RC55F2EK57"
        bundleID = "com.yce.houseDeer"
        deviceToken = "dc98d43f838bfa329588a34731b5403c74b0b7b02b678d797083c277a7090097"
        
        keyIDTF.stringValue = keyID
        TeamIDTF.stringValue = teamID
        bundleIdTF.stringValue = bundleID
        deviceTokenTF.stringValue = deviceToken
        
        

    }
    
    private func sendPush() {
        keyID = keyIDTF.stringValue
        teamID = TeamIDTF.stringValue
        bundleID = bundleIdTF.stringValue
        deviceToken = deviceTokenTF.stringValue

        guard  keyID.count > 0 else {
            return ()
        }
        guard teamID.count > 0 else {
            return ()
        }
        guard bundleID.count > 0 else {
            return ()
        }
        guard deviceToken.count > 0 else {
            return ()
        }
        
        
        var logger = Logger(label: "com.apnswift")
        logger.logLevel = .debug
        
        guard let buffer = p8Buffer, let signer = try? APNSwiftSigner.init(buffer: buffer) else {
            return ()
        }
        
        guard let apnsConfig = try? APNSwiftConfiguration.init(keyIdentifier: keyID, teamIdentifier: teamID, signer: signer, topic: bundleID, environment: envSegument.selectedSegment == 0 ? .sandbox : .production) else {
            return ()
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let apns = try? APNSwiftConnection.connect(configuration: apnsConfig, on: group.next(), logger: logger).wait()
        

        
        let dataStr = self.payloadTextView.textStorage?.string
        guard let _ = dataStr?.toDic(), let data = dataStr?.data(using: .utf8)  else {
            print("请输入正确的 json payload")
            return ()
        }
        var mutableByteBuffer = ByteBufferAllocator().buffer(capacity: data.count)
        mutableByteBuffer.writeBytes(data)

        do {
            let value = apns?.send(rawBytes: mutableByteBuffer, pushType: .alert, to: deviceToken)
            try value?.wait()
            DispatchQueue.main.async {[weak self] in
                self?.logSuccess((self?.payloadTextView.textStorage?.string ?? ""))
            }
            

        } catch let err  {
            let rErr = err as? APNSwiftError.ResponseError
            switch rErr {
            case .badRequest(let msg):
                DispatchQueue.main.async {[weak self] in
                    self?.logFaild(msg.rawValue)
                }
                
            default:
                break
            }
        }

        try? apns?.close().wait()
        try? group.syncShutdownGracefully()
    }
    
    private func logSuccess(_ text: String) {
        LogTextView.textStorage?.append((NSAttributedString.init(string: "\(Date().dateTimeString()): PUSH SUCCESS\n", attributes: [.font: NSFont.systemFont(ofSize: 20),.foregroundColor: NSColor.green])))
        logScrollToBottom()
        LogTextView.textStorage?.append((NSAttributedString.init(string: "CONTENT: \(text) " + "\n\n", attributes: [.font: NSFont.systemFont(ofSize: 18),.foregroundColor: NSColor.green])))
        
    }
    
    private func logFaild(_ text: String) {
        LogTextView.textStorage?.append((NSAttributedString.init(string: "\(Date().dateTimeString()): PUSH FAILD\n", attributes: [.font: NSFont.systemFont(ofSize: 20),.foregroundColor: NSColor.red])))
        logScrollToBottom()
        LogTextView.textStorage?.append((NSAttributedString.init(string: "REASON: \(text) " + "\n\n", attributes: [.font: NSFont.systemFont(ofSize: 18),.foregroundColor: NSColor.red])))
        
    }
    
    private func logScrollToBottom() {
        if let text = LogTextView.textStorage?.string {
            self.LogTextView.scrollRangeToVisible(NSMakeRange(text.count, 0))
        }
    }

}
