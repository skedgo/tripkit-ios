//
//  RXCocoa+NSManagedObjectContext.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/03/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation
import CoreData

import RxSwift

#if os(iOS) || os(tvOS) || os(visionOS)

  fileprivate class FetchedResultsControllerDelegateProxy<E: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    fileprivate let observer: AnyObserver<[E]>
    
    fileprivate init(_ observer: AnyObserver<[E]>) {
      self.observer = observer
    }
    
    fileprivate func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      guard let objects = controller.fetchedObjects else { return }
      let converted = objects.compactMap { $0 as? E }
      observer.onNext(converted)
    }
  }

  extension Reactive where Base: NSManagedObjectContext {
    public func fetchObjects<E: NSManagedObject>(_ entity: E.Type, sortDescriptors: [NSSortDescriptor], predicate: NSPredicate? = nil, relationshipKeyPathsForPrefetching: [String]? = nil) -> Observable<[E]> {
      
      let base = self.base
      
      return Observable.create { observer in
        
        // configure the request
        let request = entity.fetchRequest()
        request.predicate  = predicate
        request.sortDescriptors = sortDescriptors
        request.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
        request.resultType = NSFetchRequestResultType.managedObjectResultType

        // hang on to these, so that we can release them in the disposable
        var controller: NSFetchedResultsController<NSFetchRequestResult>?
        var delegate: FetchedResultsControllerDelegateProxy<E>?
        
        // set up the work and delegate forwarding messages to the delegate proxy
        controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: base, sectionNameKeyPath: nil, cacheName: nil)
        delegate = FetchedResultsControllerDelegateProxy<E>(observer)
        controller!.delegate = delegate
        do {
          try controller!.performFetch()
        } catch {
          observer.onError(error)
        }
        
        // we start with the current objects or an empty list
        let fetched = controller!.fetchedObjects ?? []
        observer.onNext(fetched.compactMap { $0 as? E })
        
        // clean-up
        return Disposables.create() {
          delegate = nil
          controller = nil
        }
      }
    }
  }

#endif
