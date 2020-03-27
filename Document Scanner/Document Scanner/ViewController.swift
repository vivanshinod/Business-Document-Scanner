//
//  ViewController.swift
//  Document Scanner
//
//  Created by Vivan on 28/03/20.
//  Copyright © 2020 The Ace Coder. All rights reserved.
//

import Vision
import VisionKit
import UIKit

class ViewController: UIViewController,VNDocumentCameraViewControllerDelegate {
    
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: BoundingBoxImageView!
    @IBOutlet weak var btnScan: UIButton!
    var txtRecognizationRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    let txtReconizationWorkQueue = DispatchQueue(label: "TextRecognizationQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
               textView.layer.cornerRadius = 10.0
               
               imageView.layer.cornerRadius = 10.0
               btnScan.layer.cornerRadius = 10.0
               
               btnScan.addTarget(self, action: #selector(scanDocument), for: .touchUpInside)
        setupVision()
    }
    
    func setupVision(){
       txtRecognizationRequest = VNRecognizeTextRequest { (request, error) in
        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
        
        var detectedText = ""
        var boundingBoxes = [CGRect]()
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { return }
            
            detectedText += topCandidate.string
            detectedText += "\n"
            
            do {
                guard let rectangle = try topCandidate.boundingBox(for: topCandidate.string.startIndex..<topCandidate.string.endIndex) else { return }
                boundingBoxes.append(rectangle.boundingBox)
            } catch {
                // You should handle errors appropriately in your app
                print(error)
            }
        }
        
        DispatchQueue.main.async {
            self.btnScan.isEnabled = true
            
            self.textView.text = detectedText
            self.textView.flashScrollIndicators()
            
            self.imageView.load(boundingBoxes: boundingBoxes)
        }
    }
    }
    @objc func scanDocument(){
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController,animated: true)
    }
        
    private func processImage(_ image:UIImage){
        imageView.image = image
//        imageView.removeExistingBoundingBoxes()
        recognizeTextInImage(image)
    }
    
    private func recognizeTextInImage(_ image:UIImage){
        guard let cgImage = image.cgImage else {return}
        
        textView.text = ""
        btnScan.isEnabled = false
        
        txtReconizationWorkQueue.async {
                   let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                   do {
                       try requestHandler.perform([self.txtRecognizationRequest])
                   } catch {
                       print(error)
                   }
               }
    }


    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
      
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        let originalImage = scan.imageOfPage(at: 0)
        let fixedImage = reloadedImage(originalImage)
        controller.dismiss(animated: true)
        processImage(fixedImage)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }

    func reloadedImage(_ originalImage: UIImage) -> UIImage{
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }
    
    
}

