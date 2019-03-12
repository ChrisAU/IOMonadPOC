//
//  URLSession+Download.swift
//  Core
//
//  Created by Chris Nevin on 08/03/2019.
//  Copyright © 2019 Chris Nevin. All rights reserved.
//

import Foundation

extension URLSession {
    public func download(from url: URL) -> Response {
        return execute(request: URLRequest(url: url))
    }
}
