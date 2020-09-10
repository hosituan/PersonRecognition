//
//  AddNameViewController.swift
//  PersonRez
//
//  Created by Hồ Sĩ Tuấn on 10/09/2020.
//  Copyright © 2020 Hồ Sĩ Tuấn. All rights reserved.
//

import UIKit
import AVFoundation
import SkyFloatingLabelTextField

class AddNameViewController: UIViewController {
    
    private var generator:AVAssetImageGenerator!
    
    @IBOutlet weak var faceImageView: UIImageView!
    @IBOutlet weak var textField: SkyFloatingLabelTextField!
    var videoURL: URL?
    var numberOflabel = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func tapDoneButoon(_ sender: UIButton) {
        if textField.text != "" && videoURL != nil {
            if let label = getEmptyLabel() {
                getAllFrames(videoURL!, for: label)
                self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: "Warning", message: "You can't add more than 30 users!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                }))
            }
        }
    }
    
    func getEmptyLabel() -> String? {
        for i in 0..<numberOflabel {
            let label = "user\(i)"
            if userDict[label] == "" {
                return label
            }
        }
        return nil
    }
    
}

extension AddNameViewController {
    
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

