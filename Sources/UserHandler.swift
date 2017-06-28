import Foundation
import ObjectMapper


public extension Spaces {
  
  /**
   User creation. There are two possible ways how to create and authenticate user classical
   using email & password and second using onboarding token that allows to create "anonymous" user
   without email, name, password.
   
   Example of traditional method:
   ```
   let user = new User()
   user.email = "me@host.com"
   user.password = "password"
   memex.createUser(user) { error in
   guard error == nil else {
   // failed
   }
   // succeeded
   }
   
   ```
   
   Example of onboarding token method:
   ```
   let onboardingToken = "Generated and stored or retrieved from icloud"
   let user = new User()
   user.fullname = "Optional Fullname"
   memex.createUser(user, onboardingToken) { error in
   guard error == nil else {
   // failed
   }
   // succeeded
   }
   
   ```
   - parameter user: User object
   - parameter onboardingToken: Onboarding token. This token can be used for authentication.
   - parameter completion: Completion block
   */
  public func createUser(user: User,
                         onboardingToken: String? = nil,
                         completion: @escaping UserOutputs) {
    var parameters = [String: Any]()
    parameters["user"] = user.toJSON()
    parameters["onboarding_token"] = onboardingToken
    POST("users", parameters: parameters) { [weak self] response in
      if (response.httpErrorCode = 409) {
        completion(nil, MemexError.alreadyExists)
        return
      }
      completion(self?.entityFromDictionary(dictionary: response.contentDictionary?["user"]), response.error)
    }
  }
  
  /**
   Returns user object based on his ID.
   
   - parameter userID: User ID (pass nil if you want to get yourself)
   - parameter completion: Completion block
   
   */
  public func getUser(userID: Int?,
                      completion: @escaping UserOutputs) {
    let id = (userID == User.Constants.myselfUserID || userID == nil) ? "self" : "\(userID!)"
    GET("users/\(id)",
    parameters: nil) { [weak self] response in
      completion(self?.entityFromDictionary(dictionary: response.contentDictionary?["user"]), response.error)
    }
  }
  
  
  /**
   Updates user (only myself). For password change use setUserPassword method.
   
   Example:
   ```
   user.fullname = "New Fullname"
   memex.updateUser(user) { error in
     guard error == nil else {
       // failed
     }
     // succeeded
   }
   
   ```
   
   - parameter user: User object with updated values
   - parameter completion: Completion block
   
   */
  public func updateUser(user: User,
                         completion: @escaping UserOutputs) {
    var userParams = Mapper<User>().toJSON(user)
    userParams["avatar"] = nil
    if let avatar_muid = user.avatar?.MUID {
      userParams["avatar_muid"] = avatar_muid
    }
    POST("users/self",
         parameters: ["user": userParams]) { [weak self] response in
          completion(self?.entityFromDictionary(dictionary: response.contentDictionary?["user"]), response.error)
    }
  }
  
  /**
   Sets/changes authenticated user password.
   
   - parameter oldPassword: Must be preset if user.hasPassword is true
   - parameter newPassword: New user password
   - parameter completion: Completion block that returns error if action fails
   
   */
  public func setUserPassword(oldPassword: String?,
                              newPassword: String,
                              completion: @escaping VoidOutputs) {
    var parameters = [String: Any]()
    if let oldPassword = oldPassword {
      parameters["old_password"] = oldPassword
    }
    parameters["new_password"] = newPassword
    POST("users/self/change-password",
         parameters: parameters) { response in
          completion(response.error)
    }
  }
  
  /**
   Requests user backup. If this method requires to have setup email.
   
   - parameter completion: Completion block that returns error if action fails
   
   */
  @available(*, deprecated)
  public func requestBackup(completion: @escaping VoidOutputs) {
    GET("users/self/backup") { response in
      completion(response.error)
    }
  }
  
}
