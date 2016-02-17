// Playground - noun: a place where people can play

import Cocoa

struct Operator {
  let name: String
  let services: Int
  let isRealTime: Bool
  let transitTypes: [String]
  
  static func loadOperator(fromJSON JSON: [String: AnyObject]) -> Operator? {
    guard let name = JSON["name"] as? String,
          let services = JSON["numberOfServices"] as? Int,
          let realTimeRaw = JSON["realTimeStatus"] as? String,
          let transitTypes = JSON["types"] as? [String] else {
      return nil
    }
    
    let isRealTime = realTimeRaw != "INCAPABLE"
    return Operator(name: name.localizedCapitalizedString, services: services, isRealTime: isRealTime, transitTypes: transitTypes)
  }
}

struct Region {
  let country: String
  let state: String?
  let name: String
  let code: String
  let operators: [Operator]
  let extras: [String]
  
  static func loadRegion(fromJSON JSON: [String: AnyObject]) -> Region? {
    guard let centerJSON = JSON["center"] as? [String: AnyObject],
          let title = (centerJSON["title"] as? String),
          let code = JSON["code"] as? String,
          let operatorJSON = JSON["operators"] as? [[String: AnyObject]],
          let extraJSON = JSON["extraModes"] as? [[String: AnyObject]] else {
      return nil
    }
    
    let titleParts = title.characters.split(",").map { String($0).stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")) }
    
    guard let city = titleParts.first,
          let country = titleParts.last else {
      return nil
    }
    let state: String? = titleParts.count >= 3 ? titleParts[1] : nil
    
    var name = city
    if let others = centerJSON["subtitle"] as? String {
      name += " (\(others))"
    }
    
    let operators = operatorJSON.flatMap { Operator.loadOperator(fromJSON: $0) }
    let extras = extraJSON.flatMap { $0["title"] as? String }
    
    return Region(country: country, state: state, name: name, code: code, operators: operators, extras: extras)
  }
  
  func operatorsString(maxOperatorCount: Int = Int.max) -> String {
    return operators
      .map { $0.name + ($0.isRealTime ? " *" : "") }
      .suffix(maxOperatorCount)
      .joinWithSeparator(", ")
  }
  
  func modesString() -> String {
    return extras.joinWithSeparator(", ")
  }
}

extension Region: Comparable {
}

func ==(x: Region, y: Region) -> Bool {
  return x.country == y.country && x.state == y.state && x.name == y.name
}

func <(x: Region, y: Region) -> Bool {
  if x.country != y.country {
    return x.country < y.country
  }
  
  if let xs = x.state, let ys = y.state where xs != ys {
    return xs < ys
  }
  
  return x.name < y.name
}

extension Region: Hashable {
  var hashValue: Int { return "\(country).\(state).\(name)".hashValue }
}

func getJSON(url: NSURL) -> [String: AnyObject]? {
  guard let data = NSData(contentsOfURL: url),
        let JSON = try? NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers),
        let dictionary = JSON as? [String: AnyObject] else {
    return nil
  }
  return dictionary
}

// download the data from the specified server
let servers = ["baryogenesis", "inflationary", "hadron", "bigbang", "granduni"]
let operatorCount = 0
let filter: [String] = [] // ["FI_"]
let includeOperators = false

var allRegions: Set<Region> = []
for server in servers {
  guard let URL = NSURL(string: "https://\(server).buzzhives.com/satapp/regionInfo.json"),
        let json = getJSON(URL),
        let regionsJSON = json["regions"] as? [[String: AnyObject]] else {
    print("\(server) has issues.")
    continue
  }
  
  let serverRegions = regionsJSON.flatMap { Region.loadRegion(fromJSON: $0) }
  allRegions.unionInPlace(serverRegions)
  
//  break
}

let sorted = Array(allRegions).sort()

// construct the output
var string = ""
var lastCountry = ""
var hasState = false
for region in sorted {
  if filter.count > 0 {
    var good = false
    for needle in filter {
      if let _ = region.code.rangeOfString(needle) {
        good = true
        break
      }
    }
    if !good {
      continue
    }
  }
  
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
    let ops = region.operatorsString(operatorCount)
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
