
import Foundation
import KeychainSwift

class AuthorizationController {
  
  // MARK: Properties
  
  var secretStore: KeychainSwift!
  var syncLock = Lock()
  var authorizationLock = Lock()
  var internalUserToken: String? {
    didSet {
      self.persistToken(token: self.internalUserToken)
    }
  }
  weak var spaces: Spaces?
  let tokenKey: String
  var userToken: String? {
    return self.syncLock.withCriticalScope {
      self.internalUserToken
    }
  }
  
  // MARK: Lifecycle
  
  init(spaces: Spaces) {
    self.spaces = spaces
    self.secretStore = KeychainSwift()
    self.secretStore.synchronizable = false
    self.tokenKey = spaces.configuration.userTokenKey
  }
  
  // MARK: Bootstrap
  
  func bootstrap(completionHandler: @escaping ()->()) {
    dispatch_async_on_main {
      self.syncLock.lock()
      self.restorePersistedToken { token in
        if self.internalUserToken != token {
          self.internalUserToken = token
          self.spaces?.emit(event: AuthorizationStatusChangedEvent(userToken: token))
        }
        self.syncLock.unlock()
        completionHandler()
      }
    }
  }
  
  // MARK: Authorization
  
  typealias TokenResponse = (_ token: String?, _ mfa: MFAChallange?,_ error: Swift.Error?)->()
  
  func authorizeWithCredentials(credentials: Credentials,
                                completionHandler: @escaping TokenResponse) {
    self.authorizeWithBodyParameters(bodyParameters: [
      "identity": [
        "email": credentials.identifier
      ],
      "secret": [
        "password": credentials.secret
      ]
      ],
                                     completionHandler: completionHandler)
  }
  
  func authorizeWithOnboardingToken(token: String,
                                    completionHandler: @escaping TokenResponse) {
    self.authorizeWithBodyParameters(bodyParameters: [
      "secret": [
        "onboarding_token": token
      ]
      ],
                                     completionHandler: completionHandler)
  }
  
  func authorizeWithRetryToken(retryToken: String,
                               activationToken: String?,
                               completionHandler: @escaping TokenResponse) {
    
    if let activationToken = activationToken {
      self.authorizeWithBodyParameters(bodyParameters: [
        "identity": [
          "retry_token": retryToken
        ],
        "secret": [
          "activation_token": activationToken
        ]
        ],
                                       completionHandler: completionHandler)
    } else {
      self.authorizeWithBodyParameters(bodyParameters: [
        "identity": [
          "retry_token": retryToken
        ]
        ],
                                       completionHandler: completionHandler)
    }
    
  }
  
  func authorizeWithBodyParameters(bodyParameters: [String: Any], completionHandler: @escaping TokenResponse) {
    var body = bodyParameters
    var identity = bodyParameters["identity"] as? [String: Any]
    if identity == nil {
      identity = [:]
    }
    identity!["device"] = UIDevice.current.name
    body["identity"] = identity
    self.spaces?.requestor.request(
      method: .POST,
      path: "sessions/create",
      queryStringParameters: ["is_non_cookies": true],
      bodyParameters: body as AnyObject,
      completionHandler: { [weak self] content, code, headers, error in
        guard let strongSelf = self else { return };
        let token = content?["token"] as? String
        var mfa: MFAChallange?
        if let json = content?["mfa"] as? [String: Any] {
          mfa = MFAChallange(JSON: json)
        }
        if error == nil {
          strongSelf.syncLock.withCriticalScope {
            if strongSelf.internalUserToken != token {
              strongSelf.internalUserToken = token
              strongSelf.spaces?.emit(event: AuthorizationStatusChangedEvent(userToken: token))
            }
          }
        }
        completionHandler(token, mfa, error)
    })
  }
  
  func deauthorize(all: Bool = false, completionHandler: @escaping VoidOutputs) {
    var authorized = false;
    self.syncLock.withCriticalScope {
      authorized = self.internalUserToken != nil
    }
    if !authorized {
      completionHandler(nil)
      return
    }
    self.spaces?.requestor.request(
      method: .POST,
      path: all ? "sessions/invalidate" : "sessions/current/invalidate",
      queryStringParameters: nil,
      bodyParameters: nil,
      allowDeauthorization: false,
      completionHandler: { [weak self] content, code, headers, error in
        self?.syncLock.withCriticalScope {
          if (self?.internalUserToken != nil) {
            self?.internalUserToken = nil
            self?.spaces?.emit(event: AuthorizationStatusChangedEvent(userToken: nil))
          }
        }
        completionHandler(error)
    })
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
        if !self.secretStore.set(token, forKey: self.tokenKey, withAccess: KeychainSwiftAccessOptions.accessibleWhenUnlockedThisDeviceOnly) {
          if self.secretStore.lastResultCode != noErr {
            NSLog("Failed to write token to Keychain: \(self.secretStore.lastResultCode).")
          }
          throw MemexError.generic
        }
      } else {
        self.secretStore.delete(self.tokenKey)
      }
    } catch {
      NSLog("Unable to store token")
    }
  }
  
}



