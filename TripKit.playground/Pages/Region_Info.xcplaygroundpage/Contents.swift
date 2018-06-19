//: [<< Index](@previous)

import Foundation

/*:
Fetches all available regions from all servers and provides a list of all
supported cities.
*/

func fetchSortedRegions() -> [Region] {
  func getJSON(_ url: URL) -> [String: AnyObject]? {
    guard let data = Data(contentsOf: url),
      let JSON = try? JSONSerialization.jsonObject(with, options: .MutableContainers),
      let dictionary = JSON as? [String: AnyObject] else {
        return nil
    }
    return dictionary
  }
  
  // download the data from the specified server
  let servers = ["baryogenesis", "inflationary", "hadron", "bigbang", "granduni"]
  
  var allRegions: Set<Region> = []
  for server in servers {
    guard let URL = URL(string: "https://\(server).buzzhives.com/satapp/regionInfo.json"),
      let json = getJSON(URL),
      let regionsJSON = json["regions"] as? [[String: AnyObject]] else {
        print("\(server) has issues.")
        continue
    }
    
    let serverRegions = regionsJSON.flatMap { Region.loadRegion(fromJSON: $0) }
    allRegions.unionInPlace(serverRegions)
    
    break
  }
  
  
  return Array(allRegions).sort()
}


let operatorCount = 0
let filter: [String] = [] // ["FI_"]
let includeOperators = false

let sorted = fetchSortedRegions()

let filtered = sorted.filter { region in
  if filter.count == 0 {
    return true
  }
  
  var good = false
  for needle in filter {
    if let _ = region.code.range(of: needle) {
      good = true
      break
    }
  }
  return good
}

var string = ""
var lastCountry = ""
var hasState = false
for region in filtered {
  if region.country != lastCountry {
    if string.utf16.count > 0 {
      string += "\n"
    }
    string += "\(region.country): "
    lastCountry = region.country
    hasState = region.state != nil
  } else {
    string += hasState ? "; " : ", "
  }

  string += region.name
  if let state = region.state {
    string += ", \(state)"
  }

  if includeOperators {
    let ops = region.operatorsString(maxOperatorCount: operatorCount)
    if ops.utf16.count > 0 {
      string += ": " + ops
    }
    
    let exs = region.modesString()
    if exs.utf16.count > 0 {
      if ops.utf16.count == 0 {
        string += ": "
      } else {
        string += " + "
      }
      string += exs
    }
  }
}
print(string)

//: [Index](Index) - [Next >>](@next)
