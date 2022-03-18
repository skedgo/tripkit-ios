//
//  Rx+Concurrency.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 16/3/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import RxSwift
import RxCocoa

extension ObservableType {
  public func asyncMap<T>(
    _ transform: @escaping (Element) async -> T
  ) -> Observable<T> {
    return flatMapLatest { (value: Element) -> Observable<T> in
      Single.create { subscriber in
        Task {
          let output = await transform(value)
          subscriber(.success(output))
        }
        return Disposables.create()
      }
      .asObservable()
    }
  }
  
  public func asyncMap<T>(
    _ transform: @escaping (Element) async throws -> T
  ) -> Observable<T> {
    return flatMapLatest { (value: Element) -> Observable<T> in
      Single.create { subscriber in
        Task {
          do {
            let output = try await transform(value)
            subscriber(.success(output))
          } catch {
            subscriber(.failure(error))
          }
        }
        return Disposables.create()
      }
      .asObservable()
    }
  }
}

extension SharedSequenceConvertibleType {
  public func safeMap<T>(
    catchError: @escaping (Error) -> Void,
    _ transform: @escaping (Element) async throws -> T?
  ) -> SharedSequence<SharingStrategy, T> {
    return
      flatMapLatest { value -> SharedSequence<SharingStrategy, T?> in
        Observable.create { subscriber in
          Task {
            do {
              let output = try await transform(value)
              await MainActor.run {
                subscriber.onNext(output)
                subscriber.onCompleted()
              }
            } catch {
              await MainActor.run {
                catchError(error)
                subscriber.onCompleted()
              }
            }
          }
          
          return Disposables.create()
        }
        .subscribe(on: SharingStrategy.scheduler)
        .observe(on: SharingStrategy.scheduler)
        .asSharedSequence(sharingStrategy: SharingStrategy.self, onErrorRecover: { _ in
          return .empty()
        })
      }
      .compactMap { $0 }
  }
  
  public func safeMap<T>(
    catchError: @escaping (Error) -> Void,
    _ transform: @escaping (Element) throws -> T?
  ) -> SharedSequence<SharingStrategy, T> {
    return compactMap { value in
      do {
        return try transform(value)
      } catch {
        catchError(error)
        return nil
      }
    }
  }

}

extension PrimitiveSequenceType where Trait == SingleTrait {
  public static func create(_ handler: @escaping () async -> Element) -> Single<Element> {
    create { subscriber in
      Task {
        subscriber(.success(await handler()))
      }
      return Disposables.create()
    }
  }
  
  public static func create(_ handler: @escaping () async throws -> Element) -> Single<Element> {
    create { subscriber in
      Task {
        do {
          subscriber(.success(try await handler()))
        } catch {
          subscriber(.failure(error))
        }
      }
      return Disposables.create()
    }
  }
}
