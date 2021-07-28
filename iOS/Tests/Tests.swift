//
//  Tests.swift
//  Tests
//
//  Created by Wilhelm Thieme on 28/07/2021.
//

import XCTest
import CoreImage
@testable import MLClassification

class BitmapTests: XCTestCase {
    
    func testRed() throws {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        let bitmap = image.toBitmap();
        
        let floats = [Float](unsafeData: bitmap)
        XCTAssertEqual(floats, [1.0, 0, 0])
    }
    
    func testGreen() throws {
        let image = CIImage(color: .green).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        let bitmap = image.toBitmap();
        
        let floats = [Float](unsafeData: bitmap)
        XCTAssertEqual(floats, [0, 1.0, 0])
    }
    
    
    func testBlue() throws {
        let image = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        let bitmap = image.toBitmap();
        
        let floats = [Float](unsafeData: bitmap)
        XCTAssertEqual(floats, [0, 0, 1.0])
    }
    
    func testRedBGR() throws {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        let bitmap = image.toBitmap(isBGR: true);
        
        let floats = [Float](unsafeData: bitmap)
        XCTAssertEqual(floats, [0, 0, 1.0])
    }
    
    func testGreenBGR() throws {
        let image = CIImage(color: .green).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        let bitmap = image.toBitmap(isBGR: true);
        
        let floats = [Float](unsafeData: bitmap)
        XCTAssertEqual(floats, [0, 1.0, 0])
    }
    
    func testBlueBGR() throws {
        let image = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        let bitmap = image.toBitmap(isBGR: true);
        
        let floats = [Float](unsafeData: bitmap)
        XCTAssertEqual(floats, [1.0, 0, 0])
    }
    
    func testOrientation() throws {
        let image = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 2, height: 2))
        let overlay = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        let combinedImage = overlay.composited(over: image)
        let bitmap = combinedImage.toBitmap()
        let floats = [Float](unsafeData: bitmap)
        XCTAssertEqual(floats, [
                        1, 0, 0,  1, 0, 0,
                        0, 0, 1,  1, 0, 0])
    }
    
}
