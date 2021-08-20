//
//  TKServer+Image.swift
//  TripKit
//
//  Created by Brian Huang on 18/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKServer {
  
  public func upload(_ imageData: Data, onComplete handler: @escaping (Result<TKImage?, Error>) -> Void) {
    let baseURL = baseURLs(for: nil).first!
    
    let boundary = UUID().uuidString
    
    var request = URLRequest(url: baseURL.appendingPathComponent("data/user/image"))
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.setValue(TKServer.userToken(), forHTTPHeaderField: "userToken")
    request.setValue(TKServer.shared.apiKey, forHTTPHeaderField: "X-TripGo-Key")
    request.setValue(TKServer.xTripGoVersion(), forHTTPHeaderField: "X-TripGo-Version")
    
    var data = Data()
    data.append(Data("\r\n--\(boundary)\r\n".utf8))
    data.append(Data("Content-Disposition: form-data; filename=\"\("user-profile-picture")\"\r\n".utf8))
    data.append(Data("Content-Type: image/png\r\n\r\n".utf8))
    data.append(imageData)
    data.append(Data("\r\n--\(boundary)--\r\n".utf8))
    
    let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
      if let error = error { handler(.failure(error)) }
      else { handler(.success(TKImage(data: imageData))) }
    }
    
    task.resume()
  }
  
}
