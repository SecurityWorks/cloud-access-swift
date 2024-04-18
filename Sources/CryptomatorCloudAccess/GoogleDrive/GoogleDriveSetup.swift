//
//  GoogleDriveSetup.swift
//  CryptomatorCloudAccess
//
//  Created by Philipp Schmid on 01.04.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import Foundation

public class GoogleDriveSetup {
	public static var constants: GoogleDriveSetup!

	public let clientId: String
	public let redirectURL: URL
	public let sharedContainerIdentifier: String?

	public init(clientId: String, redirectURL: URL, sharedContainerIdentifier: String?) {
		self.clientId = clientId
		self.redirectURL = redirectURL
		self.sharedContainerIdentifier = sharedContainerIdentifier
	}
}
