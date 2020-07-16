//
//  WebDAVProvider.swift
//  CloudAccess
//
//  Created by Tobias Hagemann on 29.06.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

import Foundation
import Promises

public enum WebDAVProviderError: Error {
	case resolvingURLFailed
	case invalidResponse
}

private extension CloudItemMetadata {
	init(_ propfindResponseElement: PropfindResponseElement, remoteURL: URL) {
		self.name = remoteURL.lastPathComponent
		self.remoteURL = remoteURL
		self.itemType = {
			guard let collection = propfindResponseElement.collection else {
				return .unknown
			}
			return collection ? .folder : .file
		}()
		self.lastModifiedDate = propfindResponseElement.lastModified
		self.size = propfindResponseElement.contentLength
	}
}

/**
 Cloud provider for WebDAV.
 */
public class WebDAVProvider: CloudProvider {
	private static let defaultPropertyNames = ["getlastmodified", "getcontentlength", "resourcetype"]

	private let client: WebDAVClient

	public init(with client: WebDAVClient) {
		self.client = client
	}

	// MARK: - CloudProvider API

	public func fetchItemMetadata(at remoteURL: URL) -> Promise<CloudItemMetadata> {
		precondition(remoteURL.isFileURL)
		guard let url = resolve(remoteURL) else {
			return Promise(WebDAVProviderError.resolvingURLFailed)
		}
		return client.PROPFIND(url: url, depth: .zero, propertyNames: WebDAVProvider.defaultPropertyNames).then { response, data -> CloudItemMetadata in
			guard let data = data else {
				throw WebDAVProviderError.invalidResponse
			}
			let parser = PropfindResponseParser(XMLParser(data: data), responseURL: response.url ?? url)
			guard let firstElement = try parser.getElements().first else {
				throw WebDAVProviderError.invalidResponse
			}
			let metadata = CloudItemMetadata(firstElement, remoteURL: remoteURL)
			guard self.validateItemType(at: remoteURL, with: metadata.itemType) else {
				throw CloudProviderError.itemTypeMismatch
			}
			return metadata
		}.recover { error -> Promise<CloudItemMetadata> in
			switch error {
			case URLSessionError.httpError(_, statusCode: 401):
				return Promise(CloudProviderError.unauthorized)
			case URLSessionError.httpError(_, statusCode: 404):
				return Promise(CloudProviderError.itemNotFound)
			case URLSessionError.httpError(URLError.notConnectedToInternet, statusCode: _):
				return Promise(CloudProviderError.noInternetConnection)
			default:
				return Promise(error)
			}
		}
	}

	public func fetchItemList(forFolderAt remoteURL: URL, withPageToken _: String?) -> Promise<CloudItemList> {
		precondition(remoteURL.isFileURL)
		precondition(remoteURL.hasDirectoryPath)
		guard let url = resolve(remoteURL) else {
			return Promise(WebDAVProviderError.resolvingURLFailed)
		}
		return client.PROPFIND(url: url, depth: .one, propertyNames: WebDAVProvider.defaultPropertyNames).then { response, data -> CloudItemList in
			guard let data = data else {
				throw WebDAVProviderError.invalidResponse
			}
			let parser = PropfindResponseParser(XMLParser(data: data), responseURL: response.url ?? url)
			let elements = try parser.getElements()
			guard let rootElement = elements.filter({ $0.depth == 1 }).first else {
				throw WebDAVProviderError.invalidResponse
			}
			let rootMetadata = CloudItemMetadata(rootElement, remoteURL: remoteURL)
			guard rootMetadata.itemType == .folder else {
				throw CloudProviderError.itemTypeMismatch
			}
			let childElements = elements.filter({ $0.depth == 1 })
			let items = childElements.map { CloudItemMetadata($0, remoteURL: remoteURL.appendingPathComponent($0.url.lastPathComponent)) }
			return CloudItemList(items: items)
		}.recover { error -> Promise<CloudItemList> in
			switch error {
			case URLSessionError.httpError(_, statusCode: 401):
				return Promise(CloudProviderError.unauthorized)
			case URLSessionError.httpError(_, statusCode: 404):
				return Promise(CloudProviderError.itemNotFound)
			case URLSessionError.httpError(URLError.notConnectedToInternet, statusCode: _):
				return Promise(CloudProviderError.noInternetConnection)
			default:
				return Promise(error)
			}
		}
	}

	public func downloadFile(from remoteURL: URL, to localURL: URL) -> Promise<Void> {
		precondition(remoteURL.isFileURL)
		precondition(localURL.isFileURL)
		precondition(!remoteURL.hasDirectoryPath)
		precondition(!localURL.hasDirectoryPath)
		guard let url = resolve(remoteURL) else {
			return Promise(WebDAVProviderError.resolvingURLFailed)
		}
		// GET requests on collections are possible so that it doesn't respond with an error as needed
		// therefore a fetchItemMetadata() is called first to ensure that it's actually a file on remote
		// CloudProviderError.itemTypeMismatch is already thrown by fetchItemMetadata() so it doesn't need to be catched
		return fetchItemMetadata(at: remoteURL).then { _ in
			return self.client.GET(url: url)
		}.then { _, fileURL -> Void in
			guard let fileURL = fileURL else {
				throw WebDAVProviderError.invalidResponse
			}
			try FileManager.default.moveItem(at: fileURL, to: localURL)
		}.recover { error -> Promise<Void> in
			switch error {
			case URLSessionError.httpError(_, statusCode: 401):
				return Promise(CloudProviderError.unauthorized)
			case URLSessionError.httpError(_, statusCode: 404):
				return Promise(CloudProviderError.itemNotFound)
			case URLSessionError.httpError(URLError.notConnectedToInternet, statusCode: _):
				return Promise(CloudProviderError.noInternetConnection)
			case CocoaError.fileWriteFileExists:
				return Promise(CloudProviderError.itemAlreadyExists)
			default:
				return Promise(error)
			}
		}
	}

	public func uploadFile(from localURL: URL, to remoteURL: URL, replaceExisting: Bool) -> Promise<CloudItemMetadata> {
		precondition(localURL.isFileURL)
		precondition(remoteURL.isFileURL)
		precondition(!localURL.hasDirectoryPath)
		precondition(!remoteURL.hasDirectoryPath)
		guard let url = resolve(remoteURL) else {
			return Promise(WebDAVProviderError.resolvingURLFailed)
		}
		guard FileManager.default.fileExists(atPath: localURL.path) else {
			return Promise(CloudProviderError.itemNotFound)
		}
		// PUT requests on existing non-collections are possible and there is no way to differentiate it for replaceExisting
		// therefore a fetchItemMetadata() is called first to make that distinction
		return fetchItemMetadata(at: remoteURL).then { _ in
			if replaceExisting {
				return self.client.PUT(url: url, fileURL: localURL)
			} else {
				return Promise(CloudProviderError.itemAlreadyExists)
			}
		}.recover { error -> Promise<(HTTPURLResponse, Data?)> in
			if case CloudProviderError.itemNotFound = error {
				return self.client.PUT(url: url, fileURL: localURL)
			} else if !replaceExisting, case CloudProviderError.itemTypeMismatch = error {
				return Promise(CloudProviderError.itemAlreadyExists)
			} else {
				return Promise(error)
			}
		}.then { response, data -> CloudItemMetadata in
			guard let data = data else {
				throw WebDAVProviderError.invalidResponse
			}
			let parser = PropfindResponseParser(XMLParser(data: data), responseURL: response.url ?? url)
			guard let firstElement = try parser.getElements().first else {
				throw WebDAVProviderError.invalidResponse
			}
			return CloudItemMetadata(firstElement, remoteURL: remoteURL)
		}.recover { error -> Promise<CloudItemMetadata> in
			switch error {
			case URLSessionError.httpError(_, statusCode: 401):
				return Promise(CloudProviderError.unauthorized)
			case URLSessionError.httpError(_, statusCode: 405):
				return Promise(CloudProviderError.itemTypeMismatch)
			case URLSessionError.httpError(_, statusCode: 409):
				return Promise(CloudProviderError.parentFolderDoesNotExist)
			case URLSessionError.httpError(_, statusCode: 507):
				return Promise(CloudProviderError.quotaInsufficient)
			case URLSessionError.httpError(URLError.notConnectedToInternet, statusCode: _):
				return Promise(CloudProviderError.noInternetConnection)
			case POSIXError.EISDIR:
				return Promise(CloudProviderError.itemTypeMismatch)
			default:
				return Promise(error)
			}
		}
	}

	public func createFolder(at remoteURL: URL) -> Promise<Void> {
		precondition(remoteURL.isFileURL)
		precondition(remoteURL.hasDirectoryPath)
		guard let url = resolve(remoteURL) else {
			return Promise(WebDAVProviderError.resolvingURLFailed)
		}
		return client.MKCOL(url: url).then { _, _ -> Void in
			// no-op
		}.recover { error -> Promise<Void> in
			switch error {
			case URLSessionError.httpError(_, statusCode: 401):
				return Promise(CloudProviderError.unauthorized)
			case URLSessionError.httpError(_, statusCode: 405):
				return Promise(CloudProviderError.itemAlreadyExists)
			case URLSessionError.httpError(_, statusCode: 409):
				return Promise(CloudProviderError.parentFolderDoesNotExist)
			case URLSessionError.httpError(_, statusCode: 507):
				return Promise(CloudProviderError.quotaInsufficient)
			case URLSessionError.httpError(URLError.notConnectedToInternet, statusCode: _):
				return Promise(CloudProviderError.noInternetConnection)
			default:
				return Promise(error)
			}
		}
	}

	public func deleteItem(at remoteURL: URL) -> Promise<Void> {
		precondition(remoteURL.isFileURL)
		guard let url = resolve(remoteURL) else {
			return Promise(WebDAVProviderError.resolvingURLFailed)
		}
		// DELETE requests have no distinction between collections and non-collections
		// therefore a fetchItemMetadata() is called first to ensure that the expected file type matches on remote
		// CloudProviderError.itemTypeMismatch is already thrown by fetchItemMetadata() so it doesn't need to be catched
		return fetchItemMetadata(at: remoteURL).then { _ in
			return self.client.DELETE(url: url)
		}.then { _, _ -> Void in
			// no-op
		}.recover { error -> Promise<Void> in
			switch error {
			case URLSessionError.httpError(_, statusCode: 401):
				return Promise(CloudProviderError.unauthorized)
			case URLSessionError.httpError(_, statusCode: 404):
				return Promise(CloudProviderError.itemNotFound)
			case URLSessionError.httpError(URLError.notConnectedToInternet, statusCode: _):
				return Promise(CloudProviderError.noInternetConnection)
			default:
				return Promise(error)
			}
		}
	}

	public func moveItem(from oldRemoteURL: URL, to newRemoteURL: URL) -> Promise<Void> {
		precondition(oldRemoteURL.isFileURL)
		precondition(newRemoteURL.isFileURL)
		precondition(oldRemoteURL.hasDirectoryPath == newRemoteURL.hasDirectoryPath)
		guard let sourceURL = resolve(oldRemoteURL), let destinationURL = resolve(newRemoteURL) else {
			return Promise(WebDAVProviderError.resolvingURLFailed)
		}
		// MOVE requests have no distinction between collections and non-collections
		// therefore a fetchItemMetadata() is called first to ensure that the expected file type matches on remote
		// CloudProviderError.itemTypeMismatch is already thrown by fetchItemMetadata() so it doesn't need to be catched
		return fetchItemMetadata(at: oldRemoteURL).then { _ in
			return self.client.MOVE(sourceURL: sourceURL, destinationURL: destinationURL)
		}.then { _, _ -> Void in
			// no-op
		}.recover { error -> Promise<Void> in
			switch error {
			case URLSessionError.httpError(_, statusCode: 401):
				return Promise(CloudProviderError.unauthorized)
			case URLSessionError.httpError(_, statusCode: 404):
				return Promise(CloudProviderError.itemNotFound)
			case URLSessionError.httpError(_, statusCode: 409):
				return Promise(CloudProviderError.parentFolderDoesNotExist)
			case URLSessionError.httpError(_, statusCode: 412):
				return Promise(CloudProviderError.itemAlreadyExists)
			case URLSessionError.httpError(_, statusCode: 507):
				return Promise(CloudProviderError.quotaInsufficient)
			case URLSessionError.httpError(URLError.notConnectedToInternet, statusCode: _):
				return Promise(CloudProviderError.noInternetConnection)
			default:
				return Promise(error)
			}
		}
	}

	// MARK: - Internal

	private func resolve(_ remoteURL: URL) -> URL? {
		guard let percentEncodedPath = remoteURL.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
			return nil
		}
		return URL(string: percentEncodedPath, relativeTo: client.baseURL)
	}

	private func validateItemType(at url: URL, with itemType: CloudItemType) -> Bool {
		return url.hasDirectoryPath == (itemType == .folder) || !url.hasDirectoryPath == (itemType == .file)
	}
}
