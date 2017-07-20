//
//  SVKServer+Agenda.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/6/17.
//


import Foundation

import RxSwift

public typealias StatusCode = Int

public enum TKAgendaUploadResult {
  case success
  case noChange
  case denied(String)
}

public enum TKAgendaFetchResult<T> {
  case success(T)
  case calculating
  case noChange
}

public enum TKAgendaUploadError: Error {
  case unexpectedResponse(StatusCode, Any?)
}

extension Reactive where Base: SVKServer {
  
  /// `POST`-ing new agenda
  public func uploadAgenda(_ input: TKAgendaInput, for components: DateComponents, overwritingDeviceId: String? = nil) -> Observable<TKAgendaUploadResult> {
    
    guard
      let year = components.year,
      let month = components.month,
      let day = components.day
    else {
      preconditionFailure("Bad components!")
    }
    
    // TODO: convert to JSON
    let paras: [String: Any] = [:]
    
    let result = requireRegions()
      .flatMapLatest { Void -> Observable<(Int, Any?)> in
        // TODO: fix region
        let region: SVKRegion? = nil
        
        return SVKServer.shared.rx.hit(
          .POST,
          path: "agenda/\(year)-\(month)-\(day)",
          parameters: paras,
          region: region)
      }
      return result.map { status, body -> TKAgendaUploadResult in
        switch status {
        case 200: return .success
        case 304: return .noChange
        // TODO: Fix owningDeviceId
        case 403: return .denied("header.owningDeviceId")
        default: throw TKAgendaUploadError.unexpectedResponse(status, body)
        }
      }
  }
  
  public func fetchAgenda(for components: DateComponents, hashCode: Int) -> Observable<TKAgendaFetchResult<TKAgendaOutput>> {
    return Observable.never()
  }
  
}
