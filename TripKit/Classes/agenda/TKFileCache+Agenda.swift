//
//  TKFileCache+Agenda.swift
//  TripKit
//
//  Created by Adrian Schönig on 14.02.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

@available(iOS 10.0, *)
extension TKFileCache {
  
  static func saveAgenda(_ data: Data, forDateString id: String) {
    TKFileCache.save(id, data: data, directory: .cache, subdirectory: "agenda")
  }
  
  static func readAgenda(forDateString id: String) -> Observable<TKAgendaOutput?> {
    guard
      let data = TKFileCache.read(id, directory: .cache, subdirectory: "agenda"),
      let observable = try? TKAgendaOutput.parse(from: data)
      else { return Observable.just(nil) }
    
    return observable.map { .some($0) }
  }
  
  static func clearAgenda(forDateString id: String) {
    TKFileCache.remove(id, directory: .cache, subdirectory: "agenda")
  }
  
  static func clearAllAgendas() {
    TKFileCache.remove(directory: .cache, subdirectory: "agenda")
  }

  
}
