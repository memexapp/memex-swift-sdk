
import Foundation
import ObjectMapper

public class URLTransform: TransformType {
  
	public typealias Object = URL
	public typealias JSON = String

	public init() {}

	public func transformFromJSON(_ value: Any?) -> URL? {
		if let URLString = value as? String {
			return URL(string: URLString)
		}
		return nil
	}

	public func transformToJSON(_ value: URL?) -> String? {
		if let URL = value {
			return URL.absoluteString
		}
		return nil
	}
}