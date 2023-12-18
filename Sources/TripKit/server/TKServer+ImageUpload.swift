//
//  TKServer+ImageUpload.swift
//  TripKit
//
//  Created by Brian Huang on 18/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKServer {
  
  public func upload(imageData: Data, contentType: String) async throws {
    let baseURL = baseURLs(for: nil).first!
    
    let boundary = UUID().uuidString
    
    var request = URLRequest(url: baseURL.appendingPathComponent("data/user/image"))
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    request.setValue(userToken, forHTTPHeaderField: "userToken")
    request.setValue(apiKey, forHTTPHeaderField: "X-TripGo-Key")
    request.setValue(TKServer.xTripGoVersion(), forHTTPHeaderField: "X-TripGo-Version")
    if let headers = TKServer.shared.customHeaders {
      for (header, value) in headers {
        request.setValue(value, forHTTPHeaderField: header)
      }
    }
    
    var uploadData = Data()
    uploadData.append(Data("\r\n--\(boundary)\r\n".utf8))
    uploadData.append(Data("Content-Disposition: form-data; filename=\"\("user-profile-picture")\"\r\n".utf8))
    uploadData.append(Data("Content-Type: \(contentType)\r\n\r\n".utf8))
    uploadData.append(imageData)
    uploadData.append(Data("\r\n--\(boundary)--\r\n".utf8))
    
    let id = UUID()
    TKLog.log("TKServer+Image", request: request, uuid: id)
    
    do {
      let (data, response) = try await URLSession.shared.upload(for: request, from: uploadData)
      TKLog.log("TKServer+Image", response: response, data: data, orError: nil, for: request, uuid: id)
      if let error = TKError.error(from: data, domain: "com.skedgo.TripKit") {
        throw error // To be consistent with what `TKServer` does
      }
    } catch let error as TKError {
      throw error // Don't log again
    } catch {
      TKLog.log("TKServer+Image", response: nil, data: nil, orError: error, for: request, uuid: id)
      throw error
    }
  }
  
  @discardableResult
  public func removeImage() async -> Int? {
    await TKServer.shared.hit(.DELETE, path: "/data/user/image").statusCode
  }

}
