//
//  TableViewController.swift
//  JankyTable
//
//  Created by Thomas Vandegriff on 5/28/19.
//  Copyright © 2019 Make School. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    private var photosDict: [String: String] = [:]
    lazy var photos = NSDictionary(dictionary: photosDict)
    lazy var phtosCache: [String: UIImage] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let plist = Bundle.main.url(forResource: "PhotosDictionary", withExtension: "plist"),
              let contents = try? Data(contentsOf: plist),
              let serializedPlist = try? PropertyListSerialization.propertyList(from: contents, format: nil),
              let serialUrls = serializedPlist as? [String: String] else {
                  print("error with serializedPlist")
                  return
              }
        photosDict = serialUrls
    }
    
    override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return photosDict.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
        let rowKey = photos.allKeys[indexPath.row] as! String
        
        
        cell = request(cell: cell, rowKey: rowKey)
        
        return cell
    }
    
    func request(cell: UITableViewCell, rowKey: String) -> UITableViewCell {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var image : UIImage?
            
            guard let imageURL = URL(string: self.photos[rowKey] as! String),
                  let imageData = try? Data(contentsOf: imageURL) else {
                      return
                  }
            
            // Simulate a network wait
            Thread.sleep(forTimeInterval: 1)
            print("sleeping 1 sec")
            
            let unfilteredImage = UIImage(data:imageData)
            image = self.applySepiaFilter(unfilteredImage!)
            
            DispatchQueue.main.async {
                // Configure the cell...
                cell.textLabel?.text = rowKey
                if image != nil {
                    cell.imageView?.image = image!
                }
            }
            
        }
        
        return cell
    }
    
    // MARK: - image processing
    
    func applySepiaFilter(_ image:UIImage) -> UIImage? {
        let inputImage = CIImage(data:image.pngData()!)
        let context = CIContext(options:nil)
        let filter = CIFilter(name:"CISepiaTone")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter!.setValue(0.8, forKey: "inputIntensity")
        
        guard let outputImage = filter!.outputImage,
              let outImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                  return nil
              }
        return UIImage(cgImage: outImage)
    }
}


