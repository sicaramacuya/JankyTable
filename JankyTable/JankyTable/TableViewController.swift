//
//  TableViewController.swift
//  JankyTable
//
//  Created by Thomas Vandegriff on 5/28/19.
//  Copyright © 2019 Make School. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    // MARK: Properties
    var photos: [Photo] = []
    let pendingOperations = PendingOperations()
    
    
    // MARK: VC's LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPhotoDetails()
    }
    
    
    // MARK: Methods
    func fetchPhotoDetails() {
        // get dataSource from plist
        guard let plist = Bundle.main.url(forResource: "PhotosDictionary", withExtension: "plist"),
              let contents = try? Data(contentsOf: plist),
              let serializedPlist = try? PropertyListSerialization.propertyList(from: contents, format: nil),
              let serialUrls = serializedPlist as? [String: String] else {
                  print("error with serializedPlist")
                  return
              }
        
        // create Photo(name, url) from dictionary
        for (name, value) in serialUrls {
            let url = URL(string: value)
            if let url = url {
                let photo = Photo(name: name, url: url)
                self.photos.append(photo)
            }
        }
        
        // reload data after updating self.photos
        self.tableView.reloadData()
    }
}


// MARK: TableView DataSource
extension TableViewController {
    override func tableView(_ tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellIdentifier", for: indexPath)
        
        let photoDetails = photos[indexPath.row]
        
        cell.textLabel?.text = photoDetails.name
        cell.imageView?.image = photoDetails.image
        
        switch photoDetails.state {
        case .filtered:
            break
        case .failed:
            cell.textLabel?.text = "Failed to load"
        case .new, .downloaded:
            if !tableView.isDragging && !tableView.isDecelerating {
                startOperations(for: photoDetails, at: indexPath)
            }
        }
        
        return cell
    }
    
    func startOperations(for photo: Photo, at indexPath: IndexPath) {
        switch photo.state {
        case .new:
            startDownload(for: photo, at: indexPath)
        case .downloaded:
            startFiltration(for: photo, at: indexPath)
        default:
            break
        }
    }
    
    func startDownload(for photo: Photo, at indexPath: IndexPath) {
        // this check the particular indexPath to see if there is already an operation in downloadsInProgress for it.
        guard pendingOperations.downloadsInPogress[indexPath] == nil else { return }
        
        let downloader = ImageDownloader(photo)
        
        // this is what we want to happend when the operation ends.
        downloader.completionBlock = {
            if downloader.isCancelled { return }
            
            DispatchQueue.main.async {
                self.pendingOperations.downloadsInPogress.removeValue(forKey: indexPath)
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
        
        // add operation to downloadsInProgress and to the downloadQueue.
        pendingOperations.downloadsInPogress[indexPath] = downloader
        pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    func startFiltration(for photo: Photo, at indexPath: IndexPath) {
        // this check the particular indexPath to see if there is already an operation in filtrationsInProgress for it.
        guard pendingOperations.filtrationsInProgress[indexPath] == nil else { return }
        
        let filter = ImageFiltration(photo)
        
        // this is what we want to happend when the operation ends.
        filter.completionBlock = {
            if filter.isCancelled { return }
            
            DispatchQueue.main.async {
                self.pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
            }
        }
        
        // add operation to filtrationsInProgress and to the filtrationQueue.
        pendingOperations.filtrationsInProgress[indexPath] = filter
        pendingOperations.filtrationQueue.addOperation(filter)
    }
}

// MARK: ScrollView Delegate
extension TableViewController {
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // as soon as user start scrolling the operations are going to be suspended
        suspendAllOperations()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            // as soon as the user stopped dragging you want to resume suspended operations, cancel operations
            // for off-screen cells, and start operations for on-screen cells
            loadImagesForOnScreenCells()
            resumeAllOperations()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // as soon as tableview stop scrolling do the same as DidEndDragging
        loadImagesForOnScreenCells()
        resumeAllOperations()
    }
    
    func suspendAllOperations() {
        pendingOperations.downloadQueue.isSuspended = true
        pendingOperations.filtrationQueue.isSuspended = true
    }
    
    func resumeAllOperations() {
        pendingOperations.downloadQueue.isSuspended = false
        pendingOperations.filtrationQueue.isSuspended = false
    }
    
    func loadImagesForOnScreenCells() {
        // start by working with all the visible rows
        if let pathsArray = tableView.indexPathsForVisibleRows {
            
            // create a set of all pending operations
            var allPendingOperations = Set(pendingOperations.downloadsInPogress.keys)
            allPendingOperations.formUnion(pendingOperations.filtrationsInProgress.keys)
            
            // create a set of operations to be cancel
            var toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray)
            toBeCancelled.subtract(visiblePaths)
            
            // create a set of operations to be started, start with index paths all visible rows
            // and then remove the ones where operations are already pending
            var toBeStarted = visiblePaths
            toBeStarted.subtract(allPendingOperations)
            
            // loop through operations to be cancelled, cancel them, and remove their reference
            // from PendingOperations
            for indexPath in toBeCancelled {
                if let pendingDownload = pendingOperations.downloadsInPogress[indexPath] { pendingDownload.cancel() }
                pendingOperations.downloadsInPogress.removeValue(forKey: indexPath)
                
                if let pendingFiltration = pendingOperations.filtrationsInProgress[indexPath] { pendingFiltration.cancel() }
                pendingOperations.filtrationsInProgress.removeValue(forKey: indexPath)
            }
            
            // loop through those to be started, and call startOperation() for each
            for indexPath in toBeStarted {
                let photoToProcess = photos[indexPath.row]
                startOperations(for: photoToProcess, at: indexPath)
            }
        }
    }
}
