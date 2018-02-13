//
//  SVKServer+Agenda.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/6/17.
//


import Foundation

import RxSwift

public typealias StatusCode = Int

// TODO: Add a .noChange here, too?
public enum TKAgendaUploadResult {
  case success
}

public enum TKAgendaFetchResult<T> {
  case success(T)
  case calculating
  case noChange
}

public enum TKAgendaError: Error {
  case userIsNotLoggedIn
  case userTokenIsInvalid
  case invalidDateComponents(DateComponents)
  case agendaInputNotAvailable(DateComponents)
  case agendaLockedByOtherDevice(owningDeviceId: String)
  case unexpectedResponse(StatusCode, Any?)
}

@available(iOS 10.0, *)
extension Reactive where Base: SVKServer {
  
  /// `POST`-ing new agenda
  ///
  /// Uploads the agenda input and the resulting observable typically
  /// indiciates if it was successful (`.success`) and if the input 
  /// didn't change (`.noChange`).
  ///
  /// The observable fails if the user is not logged in, if the agenda
  /// is locked for that day by another device (indicating that device's
  /// identifier) or if there was another unknown error.
  ///
  /// - Parameters:
  ///   - input: Agenda input for that day
  ///   - components: Day for which that input applies
  ///   - overwritingDeviceId: If the agenda for that day is locked by
  ///       another device, it can be switched to this device by providing
  ///       the owners device ID as a confirmation.
  /// - Returns: Observable as describes in notes.
  public func uploadAgenda(_ input: TKAgendaInput, for components: DateComponents, overwritingDeviceId: String? = nil) -> Observable<TKAgendaUploadResult> {
    
    guard let dateString = components.dateString else {
      preconditionFailure("Bad components!")
    }
    
    guard let _ = SVKServer.userToken() else {
      return Observable.error(TKAgendaError.userIsNotLoggedIn)
    }
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    let paras: [String: Any]?
    do {
      paras = (try encoder.encodeJSONObject(input)) as? [String: Any]
    } catch {
      return Observable.error(error)
    }
    
    return hit(.POST, path: "agenda/\(dateString)/input", parameters: paras ?? [:])
      .map { status, body, data -> TKAgendaUploadResult in
        switch status {
        case 200: return .success
        case 401: throw TKAgendaError.userTokenIsInvalid
          
        case 403:
          // TODO: Fix owningDeviceId
          throw TKAgendaError.agendaLockedByOtherDevice(owningDeviceId: "header.owningDeviceId")
        
        default: throw TKAgendaError.unexpectedResponse(status, body)
        }
      }
  }
  
  
  /// `DELETE`-ing agenda input for a day
  ///
  /// Resulting observable fires with `true` on success, `false` if 
  /// there was nothing to delete or otherwise it terminates with an
  /// error. This happens if the user is not logged in, if the agenda
  /// is locked for that day by another device (indicating that 
  /// device's identifier) or if there was another unknown error.
  ///
  /// - Parameters:
  ///   - components: Day for which to delete input
  ///   - overwritingDeviceId: If the agenda for that day is locked by
  ///       another device, it can be deleted anyway by providing the
  ///       owners device ID as a confirmation.
  /// - Returns: Observable as described in notes.
  public func deleteAgenda(for components: DateComponents, overwritingDeviceId: String? = nil) -> Observable<Bool> {
    
    guard let dateString = components.dateString else {
      preconditionFailure("Bad components!")
    }
    
    guard let _ = SVKServer.userToken() else {
      return Observable.error(TKAgendaError.userIsNotLoggedIn)
    }
    
    return hit(.DELETE, path: "agenda/\(dateString)/input")
      .map { status, body, data -> Bool in
        switch status {
        case 200: return true
        case 404: return false

        case 403:
          // TODO: Fix owningDeviceId
          throw TKAgendaError.agendaLockedByOtherDevice(owningDeviceId: "header.owningDeviceId")
          
        default: throw TKAgendaError.unexpectedResponse(status, body)
        }
      }
    
  }
  
  
  /// `GET`-s the agenda output for a day
  ///
  /// The observable will complete with `.success` and the agenda
  /// output once it is ready. This might take a while to fire, if
  /// it is still being calculated. In that case, you'll first get
  /// repeated `.calculating` callbacks every second or so.
  ///
  /// If the agenda content for the day was previously fetched
  /// and cached on the device, you can provide the hash code. In that
  /// case you'll only get a `.noChange` if there was no change.
  ///
  /// - Parameters:
  ///   - components: The day for which to fetch the agenda
  ///   - hashCode: Optional hash code of previously returned agend
  /// - Returns: Observable as described in notes
  public func fetchAgenda(for components: DateComponents, hashCode: Int? = nil) -> Observable<TKAgendaFetchResult<TKAgendaOutput>> {
    
    guard let dateString = components.dateString else {
      preconditionFailure("Bad components!")
    }
    
    guard let _ = SVKServer.userToken() else {
      return Observable.error(TKAgendaError.userIsNotLoggedIn)
    }

    var path = "agenda/\(dateString)?v=\(TKSettings.parserJsonVersion)"
    if let hashCode = hashCode {
      path.append("&hashCode=\(hashCode)")
    }

    return hit(.GET, path: path) { status, body, data -> TimeInterval? in
        switch status {
        case 299: return 1
        default: return nil
        }
      }
      .flatMapLatest { status, body, data -> Observable<TKAgendaFetchResult<TKAgendaOutput>> in
        switch status {
        case 200:
          guard let data = data, let response = body as? [String: Any] else { throw TKAgendaError.unexpectedResponse(status, body) }
          let decoder = JSONDecoder()
          decoder.dateDecodingStrategy = .iso8601
          let output = try decoder.decode(TKAgendaOutput.self, from: data)
          return try output.addTrips(fromResponse: response).map { .success($0) }
          
        case 299: return Observable.just(.calculating)
        case 304: return Observable.just(.noChange)
        case 401: throw TKAgendaError.userTokenIsInvalid
        case 404: throw TKAgendaError.agendaInputNotAvailable(components)
        default:  throw TKAgendaError.unexpectedResponse(status, body)
        }
      }
  }
  
  
  public func fetchAgendaSummary() -> Observable<TKAgendaSummary> {

    guard let _ = SVKServer.userToken() else {
      return Observable.error(TKAgendaError.userIsNotLoggedIn)
    }
    
    return hit(.GET, path: "agenda/summary")
      .map { status, body, data -> TKAgendaSummary in
        switch status {
        case 200:
          guard let data = data else {
            throw TKAgendaError.unexpectedResponse(status, body)
          }
          let decoder = JSONDecoder()
          decoder.dateDecodingStrategy = .iso8601
          return try decoder.decode(TKAgendaSummary.self, from: data)
        case 401: throw TKAgendaError.userTokenIsInvalid
        default:  throw TKAgendaError.unexpectedResponse(status, body)
        }
      }

  }
  
}


extension DateComponents {
  
  public var dateString: String? {
    guard
      let year = self.year,
      let month = self.month,
      let day = self.day
    else {
        return nil
    }
    
    return String(format: "%04d-%02d-%02d", year, month, day)
  }
  
}
