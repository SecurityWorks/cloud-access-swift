//
//  CloudPathTests.swift
//  CloudAccessTests
//
//  Created by Tobias Hagemann on 24.08.20.
//  Copyright © 2020 Skymatic GmbH. All rights reserved.
//

import Foundation
import XCTest
@testable import CloudAccess

class CloudPathTests: XCTestCase {
	func testTrimmingLeadingCharacters() {
		XCTAssertEqual("foo", "///foo".trimmingLeadingCharacters(in: CharacterSet(charactersIn: "/")))
		XCTAssertEqual("foo///bar", "/foo///bar".trimmingLeadingCharacters(in: CharacterSet(charactersIn: "/")))
		XCTAssertEqual("foo///bar", "foo///bar".trimmingLeadingCharacters(in: CharacterSet(charactersIn: "/")))
	}

	func testTrimmingTrailingCharacters() {
		XCTAssertEqual("foo", "foo///".trimmingTrailingCharacters(in: CharacterSet(charactersIn: "/")))
		XCTAssertEqual("foo///bar", "foo///bar/".trimmingTrailingCharacters(in: CharacterSet(charactersIn: "/")))
		XCTAssertEqual("foo///bar", "foo///bar".trimmingTrailingCharacters(in: CharacterSet(charactersIn: "/")))
	}

	func testStandardized() {
		let cloudPath = CloudPath("/../../foo/bar/.///../baz").standardized
		XCTAssertEqual("/../../foo/baz", cloudPath.path)
	}

	func testPathComponents() {
		XCTAssertEqual(["/", "foo", "bar"], CloudPath("/foo/bar/").pathComponents)
		XCTAssertEqual(["/", "foo", "bar"], CloudPath("/foo/bar").pathComponents)
		XCTAssertEqual(["/", "foo"], CloudPath("/foo/").pathComponents)
		XCTAssertEqual(["/", "foo"], CloudPath("/foo").pathComponents)
		XCTAssertEqual(["foo"], CloudPath("foo/").pathComponents)
		XCTAssertEqual(["foo"], CloudPath("foo").pathComponents)

		XCTAssertEqual(["/", "foo"], CloudPath("///foo///").pathComponents)
		XCTAssertEqual(["foo"], CloudPath("foo///").pathComponents)
		XCTAssertEqual(["/", "foo"], CloudPath("///foo").pathComponents)
		XCTAssertEqual(["foo", "bar"], CloudPath("foo///bar").pathComponents)

		XCTAssertEqual(["/", ".."], CloudPath("/../").pathComponents)
		XCTAssertEqual(["/", ".."], CloudPath("/..").pathComponents)
		XCTAssertEqual([".."], CloudPath("../").pathComponents)
		XCTAssertEqual([".."], CloudPath("..").pathComponents)
		XCTAssertEqual(["/", "."], CloudPath("/./").pathComponents)
		XCTAssertEqual(["/", "."], CloudPath("/.").pathComponents)
		XCTAssertEqual(["."], CloudPath("./").pathComponents)
		XCTAssertEqual(["."], CloudPath(".").pathComponents)

		XCTAssertEqual(["/"], CloudPath("/").pathComponents)
		XCTAssertEqual([""], CloudPath("").pathComponents)
	}

	func testLastPathComponent() {
		XCTAssertEqual("bar", CloudPath("/foo/bar/").lastPathComponent)
		XCTAssertEqual("bar", CloudPath("/foo/bar").lastPathComponent)
		XCTAssertEqual("foo", CloudPath("/foo/").lastPathComponent)
		XCTAssertEqual("foo", CloudPath("/foo").lastPathComponent)
		XCTAssertEqual("foo", CloudPath("foo/").lastPathComponent)
		XCTAssertEqual("foo", CloudPath("foo").lastPathComponent)

		XCTAssertEqual("foo", CloudPath("///foo///").lastPathComponent)
		XCTAssertEqual("foo", CloudPath("foo///").lastPathComponent)
		XCTAssertEqual("foo", CloudPath("///foo").lastPathComponent)
		XCTAssertEqual("bar", CloudPath("foo///bar").lastPathComponent)

		XCTAssertEqual("..", CloudPath("/../").lastPathComponent)
		XCTAssertEqual("..", CloudPath("/..").lastPathComponent)
		XCTAssertEqual("..", CloudPath("../").lastPathComponent)
		XCTAssertEqual("..", CloudPath("..").lastPathComponent)
		XCTAssertEqual(".", CloudPath("/./").lastPathComponent)
		XCTAssertEqual(".", CloudPath("/.").lastPathComponent)
		XCTAssertEqual(".", CloudPath("./").lastPathComponent)
		XCTAssertEqual(".", CloudPath(".").lastPathComponent)

		XCTAssertEqual("/", CloudPath("/").lastPathComponent)
		XCTAssertEqual("", CloudPath("").lastPathComponent)
	}

	func testAppendingPathComponent() {
		XCTAssertEqual("/foo//bar/", CloudPath("/foo/").appendingPathComponent("/bar/").path)
		XCTAssertEqual("/foo//bar", CloudPath("/foo/").appendingPathComponent("/bar").path)
		XCTAssertEqual("/foo/bar/", CloudPath("/foo/").appendingPathComponent("bar/").path)
		XCTAssertEqual("/foo/bar", CloudPath("/foo/").appendingPathComponent("bar").path)

		XCTAssertEqual("/foo/bar/", CloudPath("/foo").appendingPathComponent("/bar/").path)
		XCTAssertEqual("/foo/bar", CloudPath("/foo").appendingPathComponent("/bar").path)
		XCTAssertEqual("/foo/bar/", CloudPath("/foo").appendingPathComponent("bar/").path)
		XCTAssertEqual("/foo/bar", CloudPath("/foo").appendingPathComponent("bar").path)

		XCTAssertEqual("foo//bar/", CloudPath("foo/").appendingPathComponent("/bar/").path)
		XCTAssertEqual("foo//bar", CloudPath("foo/").appendingPathComponent("/bar").path)
		XCTAssertEqual("foo/bar/", CloudPath("foo/").appendingPathComponent("bar/").path)
		XCTAssertEqual("foo/bar", CloudPath("foo/").appendingPathComponent("bar").path)

		XCTAssertEqual("foo/bar/", CloudPath("foo").appendingPathComponent("/bar/").path)
		XCTAssertEqual("foo/bar", CloudPath("foo").appendingPathComponent("/bar").path)
		XCTAssertEqual("foo/bar/", CloudPath("foo").appendingPathComponent("bar/").path)
		XCTAssertEqual("foo/bar", CloudPath("foo").appendingPathComponent("bar").path)

		XCTAssertEqual("///foo//////bar///", CloudPath("///foo///").appendingPathComponent("///bar///").path)
		XCTAssertEqual("/foo", CloudPath("/").appendingPathComponent("foo").path)
		XCTAssertEqual("foo", CloudPath("").appendingPathComponent("foo").path)
	}

	func testDeletingLastPathComponent() {
		XCTAssertEqual("/foo/", CloudPath("/foo/bar/").deletingLastPathComponent().path)
		XCTAssertEqual("/foo/", CloudPath("/foo/bar").deletingLastPathComponent().path)
		XCTAssertEqual("/", CloudPath("/foo/").deletingLastPathComponent().path)
		XCTAssertEqual("/", CloudPath("/foo").deletingLastPathComponent().path)
		XCTAssertEqual("./", CloudPath("foo/").deletingLastPathComponent().path)
		XCTAssertEqual("./", CloudPath("foo").deletingLastPathComponent().path)

		XCTAssertEqual("///", CloudPath("///foo///").deletingLastPathComponent().path)
		XCTAssertEqual("./", CloudPath("foo///").deletingLastPathComponent().path)
		XCTAssertEqual("///", CloudPath("///foo").deletingLastPathComponent().path)
		XCTAssertEqual("foo///", CloudPath("foo///bar").deletingLastPathComponent().path)

		XCTAssertEqual("/../../", CloudPath("/../").deletingLastPathComponent().path)
		XCTAssertEqual("/../../", CloudPath("/..").deletingLastPathComponent().path)
		XCTAssertEqual("../../", CloudPath("../").deletingLastPathComponent().path)
		XCTAssertEqual("../../", CloudPath("..").deletingLastPathComponent().path)
		XCTAssertEqual("/../", CloudPath("/./").deletingLastPathComponent().path)
		XCTAssertEqual("/../", CloudPath("/.").deletingLastPathComponent().path)
		XCTAssertEqual("../", CloudPath("./").deletingLastPathComponent().path)
		XCTAssertEqual("../", CloudPath(".").deletingLastPathComponent().path)

		XCTAssertEqual("/../", CloudPath("/").deletingLastPathComponent().path)
		XCTAssertEqual("../", CloudPath("").deletingLastPathComponent().path)
	}
}
