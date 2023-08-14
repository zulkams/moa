import UIKit
import XCTest

class MoaLoggerHttpImageDownloaderTests: XCTestCase {
  override func tearDown() {
    super.tearDown()
    
    StubHttp.removeAllStubs()
  }
  
  // MARK: - startDownload
  
  var logTypes = [MoaLogType]()
  var logUrls = [String]()
  var logStatusCodes = [Int?]()
  var logErrors = [Error?]()
  
  func testLogger(type: MoaLogType, url: String, statusCode: Int?, error: Error?) {
    logTypes.append(type)
    logUrls.append(url)
    logStatusCodes.append(statusCode)
    logErrors.append(error)
  }
  
  func testLogger_startDownloadSuccess() {
    StubHttp.with35pxJpgImage()
    
    var imageFromCallback: UIImage?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image

      },
      onError: { error, response in
      }
    )
    
    // Log the request
    // -------------
    
    XCTAssertEqual(1, logTypes.count)
    XCTAssertEqual(MoaLogType.requestSent, logTypes[0])
    XCTAssertEqual("http://evgenii.com/moa/35px.jpg", logUrls[0])
    XCTAssert(logStatusCodes[0] == nil)
    XCTAssert(logErrors[0] == nil)
    
    moa_eventually(imageFromCallback != nil) {
      // Log the successful response
      // -------------
      
      XCTAssertEqual(2, self.logTypes.count)
      XCTAssertEqual(MoaLogType.responseSuccess, self.logTypes[1])
      XCTAssertEqual("http://evgenii.com/moa/35px.jpg", self.logUrls[1])
      XCTAssertEqual(200, self.logStatusCodes[1])
      XCTAssert(self.logErrors[1] == nil)
    }
  }
  
  func testLogger_startDownloadError() {
    StubHttp.withText("error", forUrlPart: "35px.jpg", statusCode: 404)
    
    var errorFromCallback: Error?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { _ in },
      onError: { error, _ in
        errorFromCallback = error
      }
    )
    
    moa_eventually(errorFromCallback != nil) {
      // Log the error response
      // -------------
      
      XCTAssertEqual(2, self.logTypes.count)
      XCTAssertEqual(MoaLogType.responseError, self.logTypes[1])
      XCTAssertEqual("http://evgenii.com/moa/35px.jpg", self.logUrls[1])
      XCTAssertEqual(404, self.logStatusCodes[1])
      
      let moaError = self.logErrors[1] as! MoaError
      XCTAssertEqual("Response HTTP status code is not 200.", moaError.localizedDescription)
      
      XCTAssertEqual("moaTests.MoaError", self.logErrors[1]?._domain)
      XCTAssertEqual(MoaError.httpStatusCodeIsNot200._code, self.logErrors[1]?._code)
    }
  }
  
  func testLogger_cancel() {
    StubHttp.withImage("96px.png", forUrlPart: "35px.jpg", statusCode: 200, responseTime: 0.1)
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { _ in },
      onError: { _, _ in }
    )
    
    downloader.cancel()
    
    moa_eventually(0.3) {
      // Log the reponse cancel
      // -------------
      
      XCTAssertEqual(2, self.logTypes.count)
      XCTAssertEqual(MoaLogType.requestCancelled, self.logTypes[1])
      XCTAssertEqual("http://evgenii.com/moa/35px.jpg", self.logUrls[1])
      XCTAssert(self.logStatusCodes[1] == nil)
      XCTAssert(self.logErrors[1] == nil)
    }
  }
  
  func testLogger_doNotLogCancelAfterDownloadSuccess() {
    StubHttp.with35pxJpgImage()
    
    var imageFromCallback: UIImage?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
        
      },
      onError: { error, response in
      }
    )
    
    // Log the request
    // -------------
    
    XCTAssertEqual(1, logTypes.count)
    XCTAssertEqual(MoaLogType.requestSent, logTypes[0])
    XCTAssertEqual("http://evgenii.com/moa/35px.jpg", logUrls[0])
    XCTAssert(logStatusCodes[0] == nil)
    XCTAssert(logErrors[0] == nil)
    
    moa_eventually(imageFromCallback != nil) {
      downloader.cancel()
      
      // Log the successful response
      // -------------
      
      XCTAssertEqual(2, self.logTypes.count)
      XCTAssertEqual(MoaLogType.responseSuccess, self.logTypes[1])
    }
  }
  
  func testLogger_doNotLogCancelAfterError() {
    StubHttp.withText("error", forUrlPart: "35px.jpg", statusCode: 404)
    
    var errorFromCallback: Error?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { _ in },
      onError: { error, _ in
        errorFromCallback = error
      }
    )
    
    moa_eventually(errorFromCallback != nil) {
      downloader.cancel()

      // Log the error response
      // -------------
      
      XCTAssertEqual(2, self.logTypes.count)
      XCTAssertEqual(MoaLogType.responseError, self.logTypes[1])
    }
  }
}
