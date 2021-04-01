//
//  DropboxClientSetup.swift
//  CryptomatorCloudAccess
//
//  Created by Philipp Schmid on 06.10.20.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import Foundation
import ObjectiveDropboxOfficial
public enum DropboxClientSetup {
	private static var firstTimeInit = true

	public static func oneTimeSetup() {
		if firstTimeInit {
			firstTimeInit = false
			let config = DBTransportDefaultConfig(appKey: DropboxSetup.constants.appKey, appSecret: nil, userAgent: nil, asMemberId: nil, delegateQueue: nil, forceForegroundSession: false, sharedContainerIdentifier: DropboxSetup.constants.appGroupName, keychainService: DropboxSetup.constants.mainAppBundleId)
			DBClientsManager.setup(withTransport: config)
		}
	}
}
