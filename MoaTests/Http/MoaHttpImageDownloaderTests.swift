import UIKit
import XCTest

class MoaImageDownloaderTests: XCTestCase {
  override func tearDown() {
    super.tearDown()
    
    StubHttp.removeAllStubs()
    Moa.settings.requestTimeoutSeconds = 30
  }
  
  // MARK: - startDownload
  
  func testLogger(type: MoaLogType, message: String, statusCode: Int?, error: Error?) { }
  
  func testStartDownload_success() {
    StubHttp.with35pxJpgImage()
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    moa_eventually(imageFromCallback != nil) {
      XCTAssertEqual(35, imageFromCallback!.size.width)
      XCTAssert(errorFromCallback == nil)
      XCTAssert(httpUrlResponseFromCallback == nil)
      XCTAssertFalse(downloader.cancelled)
    }
  }
  
  func testStartDownload_error() {
    StubHttp.withText("error", forUrlPart: "35px.jpg", statusCode: 404)
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    moa_eventually(errorFromCallback != nil) {
      XCTAssert(imageFromCallback == nil)
      XCTAssertEqual(MoaError.httpStatusCodeIsNot200._code, errorFromCallback!._code)
      XCTAssertEqual(1, errorFromCallback!._code)
      XCTAssertEqual("moaTests.MoaError", errorFromCallback!._domain)
      XCTAssertEqual(404, httpUrlResponseFromCallback!.statusCode)
    }
  }
  
  func testTimeoutError() {
    Moa.settings.requestTimeoutSeconds = 0.1
    StubHttp.withImage("96px.png", forUrlPart: "35px.jpg", statusCode: 200, responseTime: 0.2)
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    moa_eventually(0.3) {
      XCTAssert(imageFromCallback == nil)
      XCTAssertEqual(-1001, errorFromCallback!._code)
      XCTAssertEqual("NSURLErrorDomain", errorFromCallback!._domain)
      XCTAssert(httpUrlResponseFromCallback == nil)
    }
  }
  
  // MARK: - cancel
  
  func testCancel() {
    StubHttp.withImage("96px.png", forUrlPart: "35px.jpg", statusCode: 200, responseTime: 0.1)
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    downloader.cancel()
    
    moa_eventually(0.3) {
      XCTAssert(downloader.cancelled)
      XCTAssertEqual(URLSessionTask.State.completed, downloader.task!.state)
      XCTAssert(imageFromCallback == nil)
      XCTAssert(errorFromCallback == nil)
      XCTAssert(httpUrlResponseFromCallback == nil)
    }
  }
  
  func testCancel_onDeinit() {
    StubHttp.withImage("35px.jpg", forUrlPart: "35px.jpg", statusCode: 200, responseTime: 0.1)
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    var task: URLSessionDataTask?
  
    let closure:()->() = {
      let downloader = MoaHttpImageDownloader(logger: self.testLogger)
      downloader.startDownload("http://evgenii.com/moa/35px.jpg",
        onSuccess: { image in
          imageFromCallback = image
        },
        onError: { error, response in
          errorFromCallback = error
          httpUrlResponseFromCallback = response
        }
      )
      
     task = downloader.task!
    }
    
    closure() // downloader instance will be deallocated in the closure
    
    moa_eventually(0.3) {
      XCTAssertEqual(URLSessionTask.State.completed, task!.state)
      XCTAssert(imageFromCallback == nil)
      XCTAssert(errorFromCallback == nil)
      XCTAssert(httpUrlResponseFromCallback == nil)
    }
  }
  
  func testStartDownload_setCancelledToFalse() {
    StubHttp.with35pxJpgImage()
    
    var imageFromCallback: UIImage?
    
    let downloader = MoaHttpImageDownloader(logger: testLogger)
    downloader.cancelled = true
    
    downloader.startDownload("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in }
    )
    
    moa_eventually(imageFromCallback != nil) {
      XCTAssertFalse(downloader.cancelled)
    }
  }

}
