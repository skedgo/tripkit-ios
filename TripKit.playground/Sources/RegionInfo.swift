import Foundation

public struct Operator {
  public let name: String
  public let services: Int
  public let isRealTime: Bool
  let transitTypes: [String]
  
  public static func loadOperator(fromJSON JSON: [String: AnyObject]) -> Operator? {
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

public struct Region {
  public let country: String
  public let state: String?
  public let name: String
  public let code: String
  public let operators: [Operator]
  public let extras: [String]
  
  public static func loadRegion(fromJSON JSON: [String: AnyObject]) -> Region? {
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
  
  public func operatorsString(maxOperatorCount: Int = Int.max) -> String {
    return operators
      .map { $0.name + ($0.isRealTime ? " *" : "") }
      .suffix(maxOperatorCount)
      .joinWithSeparator(", ")
  }
  
  public func modesString() -> String {
    return extras.joinWithSeparator(", ")
  }
}

extension Region: Comparable {
}

public func ==(x: Region, y: Region) -> Bool {
  return x.country == y.country && x.state == y.state && x.name == y.name
}

public func <(x: Region, y: Region) -> Bool {
  if x.country != y.country {
    return x.country < y.country
  }
  
  if let xs = x.state, let ys = y.state where xs != ys {
    return xs < ys
  }
  
  return x.name < y.name
}

extension Region: Hashable {
  public var hashValue: Int { return "\(country).\(state).\(name)".hashValue }
}
