/*
 *  Copyright (c) 2016, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 */

import XCTest

extension XCTestCase {

    /**
     Returns current test name or `test` if it's nil.
     Since Swift 2.2 and 2.1 have different XCTest API - we need to wrap this here.
     */
    var currentTestName: String {
        return name ?? "test"
    }

    /**
     Waits for all test expectations with a default timeout.
     */
    func waitForTestExpectations() {
        waitForExpectations(timeout: 10, handler: nil)
    }
}
