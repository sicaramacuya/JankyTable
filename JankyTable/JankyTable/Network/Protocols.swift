//
//  Protocols.swift
//  JankyTable
//
//  Created by Eric Morales on 2/16/22.
//  Copyright © 2022 Make School. All rights reserved.
//

import Foundation

protocol Router {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var parameters: URLQueryItem { get }
    var method: String { get }
}

protocol Servicer {
    static func request(url: URL)
}
