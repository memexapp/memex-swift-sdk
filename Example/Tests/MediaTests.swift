import UIKit
import XCTest
import MemexSwiftSDK

class MediaTests: BaseTestCase {
  
  func testEmbededDataCreation() {
    let expectation1 =  expectation(description: "default")
    self.prepareSDK(authorize: true) { (memex, myself) in
      let media = Media()
      media.dataState = .dataValid
      media.mediaType = .source
      media.embededData = "text".data(using: .utf8)
      memex.createMedia(media: [media], completion: { (newMedia, _, _, error) in
        XCTAssertNil(error, "request failed")
        let newMedium = newMedia!.first
        XCTAssertNotNil(newMedium?.MUID, "missing ID")
        XCTAssertNotNil(newMedium?.createdAt, "missing created at")
        XCTAssertNotNil(newMedium?.updatedAt, "missing updated at")
        XCTAssertNotNil(newMedium?.embededData, "missing data")
        XCTAssertTrue(newMedium?.embededData == media.embededData, "wrong data")
        XCTAssertTrue(newMedium?.dataState == media.dataState, "wrong data state")
        XCTAssertTrue(newMedium?.state == .visible, "wrong visibility state")
        XCTAssertNotNil(newMedium?.ownerID, "missing owner")
        XCTAssertTrue(newMedium?.ownerID == myself?.ID, "wrong owner")
        expectation1.fulfill()
      })
    }
    waitForExpectations(timeout: Constants.timeout, handler: nil)
  }
  
  func testCreationWithUpload() {
    let expectation1 = expectation(description: "default")
    self.prepareSDK(authorize: true) { (memex, myself) in
      let media = Media()
      media.dataState = .waitingForNewUploadURL
      media.mediaType = MediaType.source
      memex.createMedia(media: [media], completion: { (newMedia, _, _, error) in
        XCTAssertNil(error, "request failed")
        let newMedium = newMedia!.first
        XCTAssertNotNil(newMedium, "missing media")
        XCTAssertNil(newMedium?.embededData, "non nil data")
        XCTAssertNotNil(newMedium?.dataUploadURL, "nil data upload url")
        XCTAssertTrue(newMedium?.dataState == .readyForDataUpload, "wrong data state")
        
        let originalData = "data".data(using: .utf8)
        let request = URLRequest(url: newMedium!.dataUploadURL!)
        URLSession.shared.uploadTask(with: request,
                                     from: originalData,
                                     completionHandler: { (data, response, error) in
                                      XCTAssertNil(error, "request failed")
                                      memex.markMediaAsUploaded(mediaMUID: newMedium!.MUID!,
                                                                completion: { (error) in
                                                                  XCTAssertNil(error, "request failed")
                                                                  memex.getMedia(mediaMUID: newMedium!.MUID!,
                                                                                 completion: { (getMedia, error) in
                                                                                  XCTAssertNil(error, "request failed")
                                                                                  XCTAssertNotNil(getMedia?.dataDownloadURL, "nil data download url")
                                                                                  XCTAssertTrue(getMedia?.dataState == .dataValid, "wrong data state")
                                                                                  
                                                                                  URLSession.shared.dataTask(with: getMedia!.dataDownloadURL!, completionHandler: { (downloadedData, response, error) in
                                                                                    XCTAssertNil(error, "request failed")
                                                                                    XCTAssertTrue(originalData == downloadedData, "wrong data")
                                                                                  }).resume()
                                                                                  expectation1.fulfill()
                                                                  })
                                                                  
                                                                  
                                      })
        }).resume()
        
      })
    }
    waitForExpectations(timeout: Constants.timeout, handler: nil)
  }
  
  func testPushPull() {
    let expectation1 = expectation(description: "default")
    self.prepareSDK(authorize: true) { (memex, myself) in
      let media = Media()
      media.MUID = UUID().uuidString
      media.dataState = .dataValid
      media.embededData = "text".data(using: .utf8)
      media.metadata = ["item": 1]
      media.mediaType = MediaType.source
      memex.createMedia(media: [media], completion: { (_, oldModelVersion, newModelVersion, error) in
        XCTAssertNil(error, "request failed")
        XCTAssertTrue(oldModelVersion == 0, "wrong old model version")
        XCTAssertTrue(newModelVersion == 1, "wrong new model version")
        memex.pullMedia(lastModelVersion: newModelVersion, offset: 0, completion: { (returnedMedia, modelVersion, total, more, nextOffset, error) in
          
          XCTAssertNil(error, "request failed")
          XCTAssertTrue(returnedMedia!.count == 0, "wrong number of media")
          XCTAssertTrue(total == 0, "wrong number of total")
          XCTAssertTrue(nextOffset == nil, "wrong next offset")
          XCTAssertTrue(more == false, "wrong number of total")
          XCTAssertTrue(modelVersion == newModelVersion, "wrong old model version")
          
          memex.pullMedia(lastModelVersion: nil, offset: 0, completion: { (returnedMedia, modelVersion, total, more, nextOffset, error) in
            XCTAssertNil(error, "request failed")
            XCTAssertTrue(returnedMedia!.count >= 1, "wrong number of media")
            XCTAssertTrue(returnedMedia!.filter({ $0.MUID! == media.MUID!}).count >= 1, "new media not found")
            XCTAssertTrue(total! >= 1, "wrong number of total")
            XCTAssertTrue(nextOffset == nil, "wrong next offset")
            XCTAssertTrue(more == false, "wrong number of total")
            XCTAssertTrue(modelVersion == newModelVersion, "wrong old model version")
            expectation1.fulfill()
          })
          
        })
        
      })
    }
    waitForExpectations(timeout: Constants.timeout, handler: nil)
    
  }
  
}
