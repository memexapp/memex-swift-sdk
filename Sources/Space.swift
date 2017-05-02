// ******************************************************************************
//
// Copyright © 2015, Adam Zdara. All rights reserved.
//
// All rights reserved. This source code can be used only for purposes specified
// by the given license contract signed by the rightful deputy of Adam Zdara.
// This source code can be used only by the owner of the license.
//
// Any disputes arising in respect of this agreement (license) shall be brought
// before the Municipal Court of Prague.
//
// ******************************************************************************

import Foundation
import Sushi
import ObjectMapper
import Atom

public class Space: JSONRepresentable, ObjectProtocol {
  
  public var MUID: String?
  public override var hashValue: Int {
    return self.MUID!.hashValue
  }
  public var createdAt: Date?
  public var updatedAt: Date?
  public var state: ObjectState?
  public var latitude: Double?
  public var longitude: Double?
  public var activity: Int?
  public var tagLabel: String?
  public var tagForegroundColor: Color?
  public var typeIdentifier: String?
  public var unread: Bool?
  public var ownerID: Int?
  public var representations: [Media]?
  
  public required init() {
    super.init()
  }
  
  public required init?(map: Map) {
    super.init(map: map)
  }
  
  override public func mapping(map: Map) {
    self.MUID <- map["muid"]
    self.createdAt <- map["created_at"]
    self.updatedAt <- map["updated_at"]
    self.state <- map["state"]
    self.tagLabel <- map["tag_label"]
    self.latitude <- map["latitude"]
    self.longitude <- map["longitude"]
    self.activity <- map["activity"]
    self.unread <- map["unread"]
    self.tagForegroundColor <- map["tag_color"]
    self.typeIdentifier <- map["type_identifier"]
    self.ownerID <- map["owner_id"]
  }
  
}

public func ==(lhs: Space, rhs: Space) -> Bool {
  if lhs.MUID == nil || rhs.MUID == nil {
    return lhs === rhs
  }
  return lhs.MUID == rhs.MUID
}
