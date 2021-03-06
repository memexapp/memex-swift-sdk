import UIKit
import XCTest
import MemexSwiftSDK

class AppTokenTests: BaseTestCase {
  
  func testPrepare() {
    let expectation1 = expectation(description: "default")
    prepareSDK { memex, myself  in
      expectation1.fulfill()
    }
    waitForExpectations(timeout: Constants.timeout, handler: nil)
  }
  
  func testValidAppToken() {
    let expectation1 = expectation(description: "default")
    self.prepareSDK { memex, myself in
      let user = User()
      memex.createUser(user: user, onboardingToken: UUID().uuidString, completion: { (user, error) in
        XCTAssertNil(error, "request failed")
        expectation1.fulfill()
      })
    }
    waitForExpectations(timeout: Constants.timeout, handler: nil)
  }
  
  func testInvalidAppToken() {
    let expectation1 = expectation(description: "default")
    let memex = Memex(appToken: "invalid-token", environment: .local, verbose: true)
    memex.prepare { error in
      XCTAssertNil(error, "nonnil error")
      let user = User()
      memex.createUser(user: user, onboardingToken: UUID().uuidString, completion: { (user, error) in
        XCTAssertNotNil(error, "request succeeded")
        expectation1.fulfill()
      })
    }
    waitForExpectations(timeout: Constants.timeout, handler: nil)
  }
  
//
//  func testLogoutUser() {
//    let expectation1 = expectation(description: "default")
//    self.prepareSDK { (memex, myself) in
//      let credentials = Credentials(identifier: self.mockEmail(), secret: self.mockPassword())
//      let user = User()
//      user.email = credentials.identifier
//      user.password = credentials.secret
//      memex.createUser(user: user, onboardingToken: nil, completion: { (newUser, error) in
//        XCTAssertNil(error, "request failed")
//        memex.loginUserWithUserCredentials(credentials: credentials, completion: { (error) in
//          XCTAssertNil(error, "request failed")
//          let newCredentials = Credentials(identifier: credentials.identifier, secret: self.mockPassword())
//
//        })
//      })
//    }
//    waitForExpectations(timeout: Constants.timeout, handler: nil)
//  }
}
