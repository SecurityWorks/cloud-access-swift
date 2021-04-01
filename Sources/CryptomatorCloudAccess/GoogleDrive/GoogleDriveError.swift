//
//  GoogleDriveError.swift
//  CryptomatorCloudAccess
//
//  Created by Philipp Schmid on 27.04.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

import Foundation

public enum GoogleDriveError: Error {
	case noIdentifierFound
	case unexpectedResultType
	case receivedIncompleteMetadata
	case unexpectedError
}
