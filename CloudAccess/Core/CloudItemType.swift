//
//  CloudItemType.swift
//  CloudAccess
//
//  Created by Philipp Schmid on 24.04.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

import Foundation

public enum CloudItemType: String, Codable {
	case file
	case folder
	case symlink
	case unknown
}
