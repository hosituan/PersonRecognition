//
//  AddUserViewController.swift
//  PersonRez
//
//  Created by Hồ Sĩ Tuấn on 06/09/2020.
//  Copyright © 2020 Hồ Sĩ Tuấn. All rights reserved.
//

import UIKit
import Vision
import MobileCoreServices
import AVFoundation
import FaceCropper

class UserData: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var type = "add"
    @IBOutlet weak var tableView: UITableView!
    private var generator:AVAssetImageGenerator!
    var valueSelected = ""
    var userNameAdd = ""
    var userList:[String: String] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        userList = loadLabel()
        tableView.delegate = self
        tableView.dataSource = self
        self.hideKeyboardWhenTappedAround()

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewFaceData" {
            let vc = segue.destination as! ViewFaceViewController
            let indexPath = self.tableView.indexPathForSelectedRow
            let currentCell = tableView.cellForRow(at: indexPath!)! as UITableViewCell
            vc.title = "\(valueSelected) - \(currentCell.textLabel?.text ?? "Blank User")"
            vc.indexPath = indexPath!.row
        }
    }
    

}

extension UserData: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        userList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cellID")
        let value = userList["user\(indexPath.row)"]
        if value == "" {
            cell.textLabel?.text = "\(indexPath.row). Tap here to see user!"
            if type == "add" {
                cell.textLabel?.text = "\(indexPath.row). Tap here to add user!"
            }
        }
        else {
            cell.textLabel?.text = "\(indexPath.row). " + userList["user\(indexPath.row)"]!
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        valueSelected = "user\(indexPath.row)"

        if type == "add" {
            let alert = UIAlertController(title: "Add User", message: "Enter name", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.text = ""
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: {_ in
                tableView.deselectRow(at: indexPath, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [self, weak alert] (_) in
                let textField = alert?.textFields![0]
                userNameAdd = textField!.text ?? "Unknown"
                let imagePicker = UIImagePickerController()
                imagePicker.videoQuality = .typeIFrame1280x720
                imagePicker.sourceType = .camera
                imagePicker.mediaTypes = [kUTTypeMovie as String]
                imagePicker.allowsEditing = true
                imagePicker.delegate = self
                present(imagePicker, animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        else if type == "view" {
            self.performSegue(withIdentifier: "viewFaceData", sender: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        {
            print("this is video")
            getAllFrames(videoURL, for: valueSelected)
            saveLabel(at: valueSelected, value: userNameAdd)
            userList = loadLabel()
            tableView.reloadData()
        }
    }
}

extension UserData {
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
        //trainingDataset.saveImage(image, for: label)
    }
    
}

