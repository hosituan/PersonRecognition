//
//  HomeViewController.swift
//  PersonRez
//
//  Created by Hồ Sĩ Tuấn on 09/09/2020.
//  Copyright © 2020 Hồ Sĩ Tuấn. All rights reserved.
//

import UIKit
import MBProgressHUD


class HomeViewController: UIViewController {

    var modelUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMLModel()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        if let dictionary = NSMutableDictionary(contentsOf: labelUrl){
            userDict = dictionary as! Dictionary<String,String>
            print(userDict)
        }

    }
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated);
        super.viewWillDisappear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewFace" {
            let vc = segue.destination as! UserData
            vc.type = "view"
        }
        else if segue.identifier == "addUser" {
            let vc = segue.destination as! UserData
            vc.type = "add"
        }
    }
    
    @IBAction func tapStart(_ sender: UIButton) {
        self.performSegue(withIdentifier: "startPredict", sender: nil)
    }
    @IBAction func tapPredictImage(_ sender: UIButton) {
        self.performSegue(withIdentifier: "predictImage", sender: nil)
    }
    @IBAction func tapAddUser(_ sender: UIButton) {
        self.performSegue(withIdentifier: "openAddUser", sender: nil)
    }
    @IBAction func tapViewData(_ sender: UIButton) {
        self.performSegue(withIdentifier: "viewFace", sender: nil)
    }
    @IBAction func tapTraining(_ sender: UIButton) {
        imageLabelDictionary = [:]
        
        for label in userDict.keys {
            for item in trainingDataset.getImage(label: label) {
                imageLabelDictionary[item!] = label
            }
        }
        if imageLabelDictionary != [:] {
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = "Training"
            model.startTraining(view: self.view)
        }
        else {
            
            showDialog(message: "No data!")
        }
    }
}

extension HomeViewController {
    func loadMLModel() {
        do{
            let fileManager = FileManager.default
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:true)
            let fileURL = documentDirectory.appendingPathComponent("HumanTrained.mlmodelc")
            if let model = model.loadModel(url: fileURL){
                updatableModel = model
                modelUrl = fileURL
            }
            else{
                if let modelURL = Bundle.main.url(forResource: "HumanFinal", withExtension: "mlmodelc"){
                    if let model = model.loadModel(url: modelURL){
                        print("Loaded from: \(modelURL)")
                        updatableModel = model
                        modelUrl = modelURL
                    }
                }
            }
            
            if let updatableModel = updatableModel {
                imageConstraint = model.getImageConstraint(model: updatableModel)
            }
            
        } catch(let error){
            print("initial error is \(error.localizedDescription)")
        }
    }
}
