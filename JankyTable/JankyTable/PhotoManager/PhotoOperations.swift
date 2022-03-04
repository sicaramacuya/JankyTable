//
//  PhotoOperations.swift
//  JankyTable
//
//  Created by Eric Morales on 3/3/22.
//  Copyright © 2022 Make School. All rights reserved.
//

import UIKit

// This enum contains all the possible states a photo record can be in
enum PhotoState {
    case new, downloaded, filtered, failed
}

class Photo {
    let name: String
    let url: URL
    var state: PhotoState = .new
    var image: UIImage? = UIImage(named: "Placeholder")
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
}

class PendingOperations {
    lazy var downloadsInPogress: [IndexPath: Operation] = [:]
    lazy var downloadQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Download queue"
        //queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
    
    lazy var filtrationsInProgress: [IndexPath: Operation] = [:]
    lazy var filtrationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Image Filtration queue"
        //queue.maxConcurrentOperationCount = 1
        
        return queue
    }()
}

class ImageDownloader: Operation {
    let photo: Photo
    
    init(_ photo: Photo) {
        self.photo = photo
    }
    
    override func main() {
        if isCancelled { return }
        
        guard let imageData = try? Data(contentsOf: photo.url) else { return }
        
        if isCancelled { return }
        
        // Simulate a network wait
        Thread.sleep(forTimeInterval: 1)
        print("sleeping 1 sec")
        
        if !imageData.isEmpty {
            photo.image = UIImage(data: imageData)
            photo.state = .downloaded
        } else {
            photo.image = UIImage(named: "Failed")
            photo.state = .failed
        }
    }
}

class ImageFiltration: Operation {
    let photo: Photo
    
    init(_ photo: Photo) {
        self.photo = photo
    }
    
    override func main() {
        if isCancelled { return }
        
        guard self.photo.state == .downloaded else { return }
        
        if let image = photo.image,
           let filterImage = applySepiaFilter(image) {
            photo.image = filterImage
            photo.state = .filtered
        }
    }
    
    func applySepiaFilter(_ image: UIImage) -> UIImage? {
        guard let data = image.pngData() else { return nil }
        let inputImage = CIImage(data: data)
        
        if isCancelled { return nil }
        
        let context = CIContext(options: nil)
        guard let filter = CIFilter(name: "CISepiaTone") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: "inputIntensity")
        
        if isCancelled { return nil }
        
        guard let outputImage = filter.outputImage,
              let outImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: outImage)
    }
}
