//
//  CloudProvider+CreateIntermediateFolderTests.swift
//  CryptomatorCloudAccessIntegrationTests
//
//  Created by Philipp Schmid on 12.10.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

#if canImport(CryptomatorCloudAccessCore)
import CryptomatorCloudAccessCore
#else
import CryptomatorCloudAccess
#endif
import Foundation
import Promises
import XCTest

enum CloudProviderFolderMockError: Error {
	case notMocked
}

private class CloudProviderFolderMock: CloudProvider {
	var existingFolders = [CloudPath]()
	var createdFolders = [CloudPath]()
	func fetchItemMetadata(at cloudPath: CloudPath) -> Promise<CloudItemMetadata> {
		return Promise(CloudProviderFolderMockError.notMocked)
	}

	func fetchItemList(forFolderAt cloudPath: CloudPath, withPageToken pageToken: String?) -> Promise<CloudItemList> {
		return Promise(CloudProviderFolderMockError.notMocked)
	}

	func downloadFile(from cloudPath: CloudPath, to localURL: URL, onTaskCreation: ((URLSessionDownloadTask?) -> Void)?) -> Promise<Void> {
		return Promise(CloudProviderFolderMockError.notMocked)
	}

	func uploadFile(from localURL: URL, to cloudPath: CloudPath, replaceExisting: Bool, onTaskCreation: ((URLSessionUploadTask?) -> Void)?) -> Promise<CloudItemMetadata> {
		return Promise(CloudProviderFolderMockError.notMocked)
	}

	func createFolder(at cloudPath: CloudPath) -> Promise<Void> {
		guard createdFolders.filter({ $0 == cloudPath }).isEmpty, existingFolders.filter({ $0 == cloudPath }).isEmpty else {
			return Promise(CloudProviderError.itemAlreadyExists)
		}
		createdFolders.append(cloudPath)
		return Promise(())
	}

	func deleteFile(at cloudPath: CloudPath) -> Promise<Void> {
		return Promise(CloudProviderFolderMockError.notMocked)
	}

	func deleteFolder(at cloudPath: CloudPath) -> Promise<Void> {
		return Promise(CloudProviderFolderMockError.notMocked)
	}

	func moveFile(from sourceCloudPath: CloudPath, to targetCloudPath: CloudPath) -> Promise<Void> {
		return Promise(CloudProviderFolderMockError.notMocked)
	}

	func moveFolder(from sourceCloudPath: CloudPath, to targetCloudPath: CloudPath) -> Promise<Void> {
		return Promise(CloudProviderFolderMockError.notMocked)
	}
}

class CloudProvider_CreateIntermediateFolderTests: XCTestCase {
	private var provider: CloudProviderFolderMock!

	override func setUpWithError() throws {
		provider = CloudProviderFolderMock()
	}

	func testDoesNotCreateAnyFolderForRootPath() throws {
		let expectation = XCTestExpectation(description: "Create no Folder for passed RootPath")
		provider.createFolderWithIntermediates(for: CloudPath("/")).then { _ in
			guard self.provider.createdFolders.isEmpty else {
				XCTFail("Provider created at least one folder")
				return
			}
		}.catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testCreateFolderWithIntermediates() throws {
		let expectation = XCTestExpectation(description: "Create all intermediate Folders for CloudPath")
		let path = CloudPath("/Foo/Bar")
		provider.createFolderWithIntermediates(for: path).then { _ in
			guard self.provider.createdFolders.count == 2 else {
				XCTFail("Provider created not exactly two folders")
				return
			}
			XCTAssert(self.provider.createdFolders.contains(CloudPath("/Foo")))
			XCTAssert(self.provider.createdFolders.contains(CloudPath("/Foo/Bar")))
		}.catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}

	func testCreateFolderWithIntermediatesIfAFolderAlreadyExists() throws {
		let expectation = XCTestExpectation(description: "Create folder without error for CloudPath if the parent folder already exists")
		let path = CloudPath("/Foo/Bar")
		provider.existingFolders.append(CloudPath("/Foo"))
		provider.createFolderWithIntermediates(for: path).then { _ in
			guard self.provider.createdFolders.count == 1 else {
				XCTFail("Provider created not exactly two folders")
				return
			}
			XCTAssert(self.provider.createdFolders.contains(CloudPath("/Foo/Bar")))
		}.catch { error in
			XCTFail("Error in promise: \(error)")
		}.always {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 1.0)
	}
}
