#if canImport(Testing)

import Testing

@testable import TripKit

struct TKRouterModeSelectionTest {
  
  @Test func groupedModesProvideEffectiveModesWhenFlatSelectionIsEmpty() {
    let groupedModes: Set<Set<String>> = [[
      TKTransportMode.publicTransport.modeIdentifier,
      TKTransportMode.car.modeIdentifier
    ]]
    
    let effective = TKRouter.effectiveModeIdentifiers(
      modes: [],
      groupedModeIdentifiers: groupedModes,
      fallbackModes: [TKTransportMode.walking.modeIdentifier]
    )
    
    #expect(
      effective == [
        TKTransportMode.publicTransport.modeIdentifier,
        TKTransportMode.car.modeIdentifier
      ]
    )
  }
  
  @Test func explicitGroupedSelectionCountsAsExplicitModeSelection() {
    let groupedModes: Set<Set<String>> = [[
      TKTransportMode.publicTransport.modeIdentifier,
      TKTransportMode.car.modeIdentifier
    ]]
    
    #expect(
      TKRouter.usesExplicitModeSelection(
        modes: [],
        groupedModeIdentifiers: groupedModes
      )
    )
  }
  
  @Test func fallbackModesAreUsedWhenNoExplicitSelectionIsProvided() {
    let fallbackModes: Set<String> = [
      TKTransportMode.walking.modeIdentifier,
      TKTransportMode.publicTransport.modeIdentifier
    ]
    
    let effective = TKRouter.effectiveModeIdentifiers(
      modes: nil,
      groupedModeIdentifiers: nil,
      fallbackModes: fallbackModes
    )
    
    #expect(effective == fallbackModes)
    #expect(
      TKRouter.usesExplicitModeSelection(
        modes: nil,
        groupedModeIdentifiers: nil
      ) == false
    )
  }
  
}

#endif
