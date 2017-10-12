//
//  ViewController.swift
//  CoreMLImage
//
//  Created by 邹琳 on 2017/10/10.
//  Copyright © 2017年 邹琳. All rights reserved.
//

import UIKit
import CoreML
import Vision


class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var labelPercent: UILabel!
    
    @IBOutlet weak var labelDesc: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.masksToBounds = true
    }

    @IBAction func chooseImage(_ sender: Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "拍照", style: .default) { _ in
            self.takePhoto(from: .camera)
        }
        
        let photoLibray = UIAlertAction(title: "相册", style: .default) { _ in
            self.takePhoto(from: .photoLibray)
        }
        
        let cancel = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(photoLibray)
        actionSheet.addAction(cancel)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
}

extension ViewController{
    func resize(image:UIImage, newSize:CGSize) -> UIImage?{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let size = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        image.draw(in: size)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

extension ViewController{
    enum PhotoSource {
        case camera,photoLibray
    }
    
    func takePhoto(from source:PhotoSource){
        let imagePicker = UIImagePickerController()
        
        imagePicker.sourceType = (source == .camera ? .camera : .photoLibrary)
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageView.image = image
            let fixSize = CGSize(width: 224, height: 224)
            if let newImage = resize(image: image, newSize: fixSize){
                guess(image: newImage)
            }
        }
    }
    
    func guess(image:UIImage){
        
        guard let ciImage = CIImage(image:image) else{
            fatalError("不能创建image")
        }
        
        guard let model = try? VNCoreMLModel(for: MobileNet().model) else{
            fatalError("不能加载model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation], let first = results.first else{
                fatalError("不能匹配结果")
            }
            DispatchQueue.main.async {
                self.labelDesc.text = first.identifier
                self.labelPercent.text = "\(first.confidence * 100)%"
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        
        //预测是一个资源占用型的操作
        DispatchQueue.global(qos: .userInteractive).async {
            try? handler.perform([request])
        }
    }
}












