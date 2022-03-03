//
//  Photo.swift
//  JankyTable
//
//  Created by Eric Morales on 2/17/22.
//  Copyright © 2022 Make School. All rights reserved.
//

import UIKit

typealias PhotoDownloadCompletionBlock = (_ image: UIImage?, _ error: NSError?) -> Void

enum PhotoStatus {
    case downloading
    case goodToGo
    case failed
}

protocol Photo {
    var statusImage: PhotoStatus { get }
    var image: UIImage? { get }
}

final class DownloadPhoto: Photo {
    var statusImage: PhotoStatus = .downloading
    var image: UIImage?
    let url: URL
    
    init(url: URL, completion: PhotoDownloadCompletionBlock!) {
        self.url = url
        downloadImage(completion)
    }
    
    convenience init(url: URL) {
        self.init(url: url, completion: nil)
    }
    
    private func downloadImage(_ completion: PhotoDownloadCompletionBlock?) {
        
    }
}
