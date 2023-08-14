import UIKit
import XCTest

class MoaHttpImageTests: XCTestCase {
  override func tearDown() {
    super.tearDown()
    
    StubHttp.removeAllStubs()
  }
  
  // MARK: - Integration tests
  
  func testLoad_allGood() {
    StubHttp.with35pxJpgImage()
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    let task  = MoaHttpImage.createDataTask("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    task?.resume()
    
    moa_eventually(imageFromCallback != nil) {
      XCTAssertEqual(35, imageFromCallback!.size.width)
      XCTAssert(errorFromCallback == nil)
      XCTAssert(httpUrlResponseFromCallback == nil)
    }
  }
  
  func testLoad_httpError404NotFound() {
    StubHttp.withText("error", forUrlPart: "35px.jpg", statusCode: 404)
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    let task  = MoaHttpImage.createDataTask("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    task?.resume()
    
    moa_eventually(httpUrlResponseFromCallback != nil) {
      XCTAssert(imageFromCallback == nil)
      XCTAssertEqual(MoaError.httpStatusCodeIsNot200._code, errorFromCallback!._code)
      XCTAssertEqual(1, errorFromCallback!._code)
      XCTAssertEqual("moaTests.MoaError", errorFromCallback!._domain)
      XCTAssertEqual(404, httpUrlResponseFromCallback!.statusCode)
    }
  }
  
  func testLoad_noInternetConnectionError() {
    // Code: -1009
    let notConnectedErrorCode = Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue)
    
    let notConnectedError = NSError(domain: NSURLErrorDomain,
      code: notConnectedErrorCode, userInfo: nil)
    
    StubHttp.withError(notConnectedError, forUrlPart: "evgenii.com")
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    let task  = MoaHttpImage.createDataTask("http://evgenii.com/moa/35px.jpg",
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    task?.resume()
    
    moa_eventually(errorFromCallback != nil) {
      XCTAssert(imageFromCallback == nil)
      XCTAssertEqual(-1009, errorFromCallback!._code)
      XCTAssertEqual("NSURLErrorDomain", errorFromCallback!._domain)
      XCTAssert(httpUrlResponseFromCallback == nil)
    }
  }
  
  // MARK: - handleSuccess
  
  func testHandleSuccess() {
    let data = MoaTest.nsDataFromFile("35px.jpg")
    let response = HTTPURLResponse(url: NSURL(string: "")! as URL, statusCode: 200,
      httpVersion: nil, headerFields: ["Content-Type": "image/jpeg"])!
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    MoaHttpImage.handleSuccess(data, response: response,
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    XCTAssertEqual(35, imageFromCallback!.size.width)
    XCTAssert(errorFromCallback == nil)
    XCTAssert(httpUrlResponseFromCallback == nil)
  }
  
  func testHandleError_responseCodeIsNot200() {
    let data = MoaTest.nsDataFromFile("35px.jpg")
    let response = HTTPURLResponse(url: NSURL(string: "")! as URL, statusCode: 500,
      httpVersion: nil, headerFields: ["Content-Type": "image/jpeg"])!
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    MoaHttpImage.handleSuccess(data, response: response,
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    XCTAssert(imageFromCallback == nil)
    XCTAssertEqual(MoaError.httpStatusCodeIsNot200._code, errorFromCallback!._code)
    XCTAssertEqual(1, errorFromCallback!._code)
    XCTAssertEqual("moaTests.MoaError", errorFromCallback!._domain)
    XCTAssertEqual(500, httpUrlResponseFromCallback!.statusCode)
  }
  
  func testHandleError_noContentTypeInResponse() {
    let data = MoaTest.nsDataFromFile("35px.jpg")
    let response = HTTPURLResponse(url: NSURL(string: "")! as URL, statusCode: 200,
      httpVersion: nil, headerFields: nil)!
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    MoaHttpImage.handleSuccess(data, response: response,
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    XCTAssert(imageFromCallback == nil)
    
    XCTAssertEqual(MoaError.missingResponseContentTypeHttpHeader._code,
      errorFromCallback!._code)
    
    XCTAssertEqual("moaTests.MoaError", errorFromCallback!._domain)
    XCTAssertEqual(200, httpUrlResponseFromCallback!.statusCode)
  }
  
  func testHandleError_notAnImageContentType() {
    let data = MoaTest.nsDataFromFile("35px.jpg")
    let response = HTTPURLResponse(url: NSURL(string: "")! as URL, statusCode: 200,
      httpVersion: nil, headerFields: ["Content-Type": "text/html"])!
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    MoaHttpImage.handleSuccess(data, response: response,
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    XCTAssert(imageFromCallback == nil)
    
    XCTAssertEqual(MoaError.notAnImageContentTypeInResponseHttpHeader._code,
      errorFromCallback!._code)
    
    XCTAssertEqual("moaTests.MoaError", errorFromCallback!._domain)
    XCTAssertEqual(200, httpUrlResponseFromCallback!.statusCode)
  }
  
  func testHandleError_reponseDataIsNotAnImage() {
    let data = MoaTest.nsDataFromFile("text.txt")
    let response = HTTPURLResponse(url: NSURL(string: "")! as URL, statusCode: 200,
      httpVersion: nil, headerFields: ["Content-Type": "image/jpeg"])!
    
    var imageFromCallback: UIImage?
    var errorFromCallback: Error?
    var httpUrlResponseFromCallback: HTTPURLResponse?
    
    MoaHttpImage.handleSuccess(data, response: response,
      onSuccess: { image in
        imageFromCallback = image
      },
      onError: { error, response in
        errorFromCallback = error
        httpUrlResponseFromCallback = response
      }
    )
    
    XCTAssert(imageFromCallback == nil)
    
    XCTAssertEqual(MoaError.failedToReadImageData._code,
      errorFromCallback!._code)
    
    XCTAssertEqual("moaTests.MoaError", errorFromCallback!._domain)
    XCTAssertEqual(200, httpUrlResponseFromCallback!.statusCode)
  }
}
