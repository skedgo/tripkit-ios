//
//  TKUIAutocompletionViewController+SwiftUI.swift
//  TripKit
//
//  Created by Adrian Schönig on 11/7/2025.
//

import UIKit
import MapKit
import SwiftUI

import TripKit

/// Displays autocompletion results from search
///
/// Usage example in SwiftUI:
///
/// ```swift
/// @State var searchText: String = ""
/// @State var isSearching: Bool = false
///
/// var body: some View {
///   ZStack {
///     Map()
///     if isSearching
///       TKUIAutocompletionView(
///         providers: GeocoderManager.autocompletionProviders,
///         searchText: searchText
///       ) { result in
///         // Do something with `result`...
///         isSearching = false
///       }
///     }
///   }
///   .searchable(text: $searchText, isPresented: $isSearching)
/// }
/// ```
public struct TKUIAutocompletionView: UIViewControllerRepresentable {
  public init(providers: [TKAutocompleting], searchText: String = "", biasMapRect: MKMapRect? = nil, onResult: @escaping (TKAutocompletionSelection) -> Void) {
    self.providers = providers
    self.searchText = searchText
    self.biasMapRect = biasMapRect
    self.onResult = onResult
  }
  
  let providers: [TKAutocompleting]
  let searchText: String
  let biasMapRect: MKMapRect?
  let onResult: (TKAutocompletionSelection) -> Void

  public func makeUIViewController(context: Context) -> TKUIAutocompletionViewController {
    let controller = TKUIAutocompletionViewController(providers: providers)
    controller.showAccessoryButtons = false
    controller.delegate = context.coordinator
    if let biasMapRect = biasMapRect {
      controller.biasMapRect = biasMapRect
    }
    return controller
  }

  public func updateUIViewController(
    _ uiViewController: TKUIAutocompletionViewController, context: Context
  ) {
    // Update search text by calling updateSearchResults
    let searchController = UISearchController()
    searchController.searchBar.text = searchText
    uiViewController.updateSearchResults(for: searchController)
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  public class Coordinator: NSObject, TKUIAutocompletionViewControllerDelegate {
    let parent: TKUIAutocompletionView

    init(parent: TKUIAutocompletionView) {
      self.parent = parent
    }

    public func autocompleter(
      _ controller: TKUIAutocompletionViewController, didSelect selection: TKAutocompletionSelection
    ) {
      parent.onResult(selection)
    }

    public func autocompleter(
      _ controller: TKUIAutocompletionViewController,
      didSelectAccessoryFor selection: TKAutocompletionSelection
    ) {
      assertionFailure("Shouldn't happen as we disabled this")
    }
  }
}
