//
//  RecordVideoViewController.swift
//  PersonRez
//
//  Created by Hồ Sĩ Tuấn on 09/09/2020.
//  Copyright © 2020 Hồ Sĩ Tuấn. All rights reserved.
//

import UIKit
import AVFoundation

class RecordVideoViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    
    private var generator:AVAssetImageGenerator!
    
    @IBOutlet weak var desLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var videoView: VideoView!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var movieOutput = AVCaptureMovieFileOutput()
    
    var timeRecord = 5
    var timer = Timer()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        else {
            print("Unable to access back camera!")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
        
    }
    @IBAction func startButtonTapped(_ sender: UIButton) {
        desLabel.text = "Move your head slowly!"
        startButton.isEnabled = false
        captureSession.addOutput(movieOutput)
        let paths = documentDirectory.appendingPathComponent("movie.mov")
        try? FileManager.default.removeItem(at: paths)
        movieOutput.startRecording(to: paths, recordingDelegate: self)
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    @objc func timerAction() {
        timeRecord -= 1
        startButton.setTitle("\(timeRecord) seconds remaining!", for: .disabled)
        if timeRecord == 0 {
            self.movieOutput.stopRecording()
            timer.invalidate()
            startButton.isEnabled = true
            timeRecord = 5
            startButton.setTitle("Done", for: .normal)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    func setupLivePreview() {
        print("go there")
        videoView.layer.cornerRadius = 150
        videoView.layer.masksToBounds = true
        videoView.layer.borderWidth = 1
        videoView.layer.borderColor = UIColor.green.cgColor
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = videoView.layer.bounds
        
        videoPreviewLayer.connection?.videoOrientation = .portrait
        videoView.layer.insertSublayer(videoPreviewLayer, at: 0)
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.videoView.bounds
            }
        }
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("FINISHED")
        if error == nil {
            getAllFrames(outputFileURL, for: "user7")
        }
    }
}
extension RecordVideoViewController {
    
    func getAllFrames(_ videoUrl: URL, for label: String) {
        let asset:AVAsset = AVAsset(url: videoUrl)
        let duration:Double = CMTimeGetSeconds(asset.duration)
        self.generator = AVAssetImageGenerator(asset:asset)
        self.generator.appliesPreferredTrackTransform = true
        var i: Double = 0
        repeat {
            self.getFrame(fromTime: i, for: label )
            i = i + 0.1
        } while (i < duration)
        
        self.generator = nil
    }
    
    private func getFrame(fromTime:Double, for label: String) {
        
        let time:CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: 60)
        let image:UIImage
        do {
            try image = UIImage(cgImage: self.generator.copyCGImage(at:time, actualTime:nil))
        } catch {
            return
        }
        image.face.crop { result in
            switch result {
            case .success(let faces):
                for face in faces {
                    trainingDataset.saveImage(face, for: label)
                }
            case .notFound:
                print("Not found face")
            case .failure(let error):
                print("Error crop face: \(error)")
            }
        }
    }
    
}
