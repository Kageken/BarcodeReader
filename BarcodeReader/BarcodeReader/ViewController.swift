//
//  ViewController.swift
//  BarcodeReader
//
//  Created by 陰山賢太 on 2018/10/08.
//  Copyright © 2018 Kageken. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var label: UILabel!

    let detectionArea = UIView()
    var timer: Timer!
    var counter = 0
    var isDetected = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // セッションのインスタンス生成
        let captureSession = AVCaptureSession()

        // 入力（背面カメラ）
        let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        captureSession.addInput(videoInput)

        // 出力（ビデオデータ）
        let captureOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureOutput)

        // メタデータを検出した際のデリゲート設定
        captureOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        // EAN-13コードの認識を設定
        captureOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.ean13,AVMetadataObject.ObjectType.ean8]

        // 検出エリアのビュー
        let x: CGFloat = 0.05
        let y: CGFloat = 0.3
        let width: CGFloat = 0.9
        let height: CGFloat = 0.2

        detectionArea.frame = CGRect(x: view.frame.size.width * x, y: view.frame.size.height * y, width: view.frame.size.width * width, height: view.frame.size.height * height)
        detectionArea.layer.borderColor = UIColor.red.cgColor
        detectionArea.layer.borderWidth = 3
        view.addSubview(detectionArea)

        // 検出エリアの設定
        captureOutput.rectOfInterest = CGRect(x: y,y: 1-x-width,width: height,height: width)

        // プレビュー
        if let videoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession) {
            videoLayer.frame = previewView.bounds
            videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewView.layer.addSublayer(videoLayer)
        }

        // セッションの開始
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }

        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        timer.fire()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 複数のメタデータを検出できる
        for metadata in metadataObjects as! [AVMetadataMachineReadableCodeObject] {
            // EAN-13Qコードのデータかどうかの確認
            if metadata.type == AVMetadataObject.ObjectType.ean13 || metadata.type == AVMetadataObject.ObjectType.ean8{
                if metadata.stringValue != nil {
                    // 検出データを取得
                    counter = 0
                    if !isDetected || label.text != metadata.stringValue! {
                        isDetected = true
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate) // バイブレーション
                        print(metadata.stringValue!)
                        label.text = metadata.stringValue!
                        detectionArea.layer.borderColor = UIColor.white.cgColor
                        detectionArea.layer.borderWidth = 5
                    }
                }
            }
        }
    }

    @objc func update(tm: Timer) {
        counter += 1
        print(counter)
        if 1 < counter {
            detectionArea.layer.borderColor = UIColor.red.cgColor
            detectionArea.layer.borderWidth = 3
            label.text = ""
        }
    }
}
