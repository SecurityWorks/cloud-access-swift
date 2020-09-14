//
//  CloudItemMetadata.swift
//  CloudAccess
//
//  Created by Philipp Schmid on 22.04.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

import Foundation

public struct CloudItemMetadata {
	public let name: String
	public let cloudPath: CloudPath
	public let itemType: CloudItemType
	public let lastModifiedDate: Date?
	public let size: Int?

	public init(name: String, cloudPath: CloudPath, itemType: CloudItemType, lastModifiedDate: Date?, size: Int?) {
		self.name = name
		self.cloudPath = cloudPath
		self.itemType = itemType
		self.lastModifiedDate = lastModifiedDate
		self.size = size
	}
}
