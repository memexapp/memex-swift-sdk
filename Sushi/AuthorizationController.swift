
import Foundation
import Atom

public class AuthorizationController {
  
  // MARK: Properties
  
  var secretStore: KeychainSwift!
  var syncLock = Lock()
  var authorizationLock = Lock()
  var internalUserToken: String? {
    didSet {
      self.persistToken(token: self.internalUserToken)
    }
  }
  weak var service: Service?
  let tokenKey: String
  public var userToken: String? {
    return self.syncLock.withCriticalScope {
      self.internalUserToken
    }
  }
  
  // MARK: Lifecycle
  
  init(service: Service) {
    self.service = service
    self.secretStore = KeychainSwift()
    self.tokenKey = self.service?.configuration.authTokenKey ?? "authToken"
  }
  
  // MARK: Bootstrap
  
  func bootstrap(allowDeauthorization: Bool, completionHandler: @escaping ()->()) {
    dispatch_async_on_main {
      self.syncLock.lock()
      self.restorePersistedToken { token in
        if self.internalUserToken != token {
          self.internalUserToken = token
          self.service?.emit(event: AuthorizationStatusChangedEvent(token: token))
        }
        self.syncLock.unlock()
      }
      completionHandler()
    }
  }
  
  // MARK: Authorization
  
  typealias TokenResponse = (_ token: String?, _ error: Swift.Error?)->()
  
  func authorizeWithCredentials(credentials: Credentials,
                                completionHandler: @escaping TokenResponse) {
    self.authorizeWithBodyParameters(bodyParameters: [
      "user": [
        "email": credentials.identifier
      ],
      "secrets": [
        "password": credentials.secret
      ]
      ],
                                     completionHandler: completionHandler)
  }
  
  func authorizeWithUUID(UUID: String,
                         completionHandler: @escaping TokenResponse) {
    self.authorizeWithBodyParameters(bodyParameters: [
      "secrets": [
        "uuid": UUID
      ]
      ],
                                     completionHandler: completionHandler)
  }
  
  func authorizeWithBodyParameters(bodyParameters: [String: Any], completionHandler: @escaping TokenResponse) {
    self.service?.requestor.request(
      method: .POST,
      path: "auth/user",
      queryStringParameters: nil,
      bodyParameters: bodyParameters,
      completionHandler: { [weak self] content, code, error in
        let token = content?["token"] as? String
        if error == nil {
          self?.syncLock.withCriticalScope {
            self?.internalUserToken = token
          }
        }
        completionHandler(token, error)
    })
  }
  
  func deauthorize() {
    self.syncLock.withCriticalScope {
      self.internalUserToken = nil
    }
  }
  
  // MARK: Access Token Persistency
  
  private func restorePersistedToken(completion: @escaping (String?)->()) {
    let token = self.secretStore.get(self.tokenKey)
    if self.secretStore.lastResultCode != noErr {
      NSLog("Failed to read from Keychain: \(self.secretStore.lastResultCode). try after 0.1s")
      dispatch_async_on_main(delay: 0.5) { //https://forums.developer.apple.com/thread/4743
        let token = self.secretStore.get(self.tokenKey)
        if self.secretStore.lastResultCode != noErr {
          NSLog("Failed to read from Keychain again: \(self.secretStore.lastResultCode). try after 0.5s")
          dispatch_async_on_main(delay: 1.5) {
            let token = self.secretStore.get(self.tokenKey)
            completion(token)
          }
        } else {
          completion(token)
        }
      }
    } else {
      completion(token)
    }
  }
  
  
  private func persistToken(token: String?) {
    do {
      if let token = token {
        // remove always access options after //https://forums.developer.apple.com/thread/4743 is fixed
        if !self.secretStore.set(token, forKey: self.tokenKey, withAccess: KeychainSwiftAccessOptions.accessibleAlways) {
          if self.secretStore.lastResultCode != noErr {
            NSLog("Failed to write token to Keychain: \(self.secretStore.lastResultCode).")
          }
          throw Error.generic
        }
      } else {
        self.secretStore.delete(self.tokenKey)
      }
    } catch {
      NSLog("Unable to store token")
    }
  }
  
}



