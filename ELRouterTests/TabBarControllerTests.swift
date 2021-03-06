//
//  TabBarControllerTests.swift
//  ELRouter
//
//  Created by Angelo Di Paolo on 12/1/15.
//  Copyright © 2015 Walmart. All rights reserved.
//

// Need to convert this stuff to functional tests.

/*import XCTest
import UIKit
import ELFoundation
@testable import ELRouter

class TabBarControllerTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
    }
    
    func test_navigator_properTabIsSelectedWhenEvaluatingComponent() {
        let router = Router()
        let tabBarController = UITabBarController(nibName: nil, bundle: nil)
        router.navigator = tabBarController
        
        let tabOneExpectation = expectationWithDescription("tab one created")
        let tabTwoExpectation = expectationWithDescription("tab two created")

        router.register(Route("tabOne", type: .Static) { _, _ in
            tabOneExpectation.fulfill()
            let vc = UIViewController(nibName: nil, bundle: nil)
            return UINavigationController(rootViewController: vc)
        })
        
        router.register(Route("tabTwo", type: .Static) { _, _ in
            tabTwoExpectation.fulfill()
            let vc = UIViewController(nibName: nil, bundle: nil)
            return UINavigationController(rootViewController: vc)
        })
        
        router.updateNavigator()
        
        router.evaluate(["tabTwo"], associatedData: nil)
        
        do {
            try waitForConditionsWithTimeout(2.0) { () -> Bool in
                return tabBarController.selectedIndex == 1
            }
        } catch {
            XCTFail()
        }

        waitForExpectationsWithTimeout(2.0) { (error) -> Void in
            XCTAssertNotNil(router.navigator)
            XCTAssertEqual(tabBarController.selectedIndex, 1)
            XCTAssertEqual(router.navigator!.selectedIndex, 1)
        }
    }
    
    func test_navigator_properTabIsSelectedWhenEvaluatingSimpleURL() {
        let router = Router()
        let tabBarController = UITabBarController(nibName: nil, bundle: nil)
        router.navigator = tabBarController
        
        let tabOneExpectation = expectationWithDescription("tab one created")
        let tabTwoExpectation = expectationWithDescription("tab two created")
        let tabThreeExpectation = expectationWithDescription("tab three created")

        router.register(Route("tabOne", type: .Static) { _, _ in
            tabOneExpectation.fulfill()
            let vc = UIViewController(nibName: nil, bundle: nil)
            return UINavigationController(rootViewController: vc)
        })
        
        router.register(Route("tabTwo", type: .Static) { _, _ in
            tabTwoExpectation.fulfill()
            let vc = UIViewController(nibName: nil, bundle: nil)
            return UINavigationController(rootViewController: vc)
        })
        
        router.register(Route("tabThree", type: .Static) { _, _ in
            tabThreeExpectation.fulfill()
            let vc = UIViewController(nibName: nil, bundle: nil)
            return UINavigationController(rootViewController: vc)
        })
        
        router.updateNavigator()
        
        router.evaluateURL(NSURL(string: "scheme://tabThree")!)
        
        do {
            try waitForConditionsWithTimeout(2.0) { () -> Bool in
                return tabBarController.selectedIndex == 2
            }
        } catch {
            XCTFail()
        }
        
        waitForExpectationsWithTimeout(2.0) { (error) -> Void in
            XCTAssertNotNil(router.navigator)
            XCTAssertEqual(tabBarController.selectedIndex, 2)
            XCTAssertEqual(router.navigator!.selectedIndex, 2)
        }
    }
    
    func test_navigator_evaluateFailsWithBogusURL() {
        let router = Router()
        let tabBarController = UITabBarController(nibName: nil, bundle: nil)
        router.navigator = tabBarController
        
        let tabTwoExpectation = expectationWithDescription("route handler should run")
        
        router.register(Route("tabOne", type: .Static) { _, _ in
            XCTAssertTrue(true, "Tab one handler should not be run when evaluating tab two")
            let vc = UIViewController(nibName: nil, bundle: nil)
            return UINavigationController(rootViewController: vc)
            })
        
        router.register(Route("tabTwo", type: .Static) { _, _ in
            tabTwoExpectation.fulfill()
            let vc = UIViewController(nibName: nil, bundle: nil)
            return UINavigationController(rootViewController: vc)
            })
        
        router.register(Route("tabThree", type: .Static) { _, _ in
            XCTAssertTrue(true, "Tab two handler should not be run when evaluating tab three")
            let vc = UIViewController(nibName: nil, bundle: nil)
            return UINavigationController(rootViewController: vc)
            })
        
        router.updateNavigator()
        
        // this route doesn't exist, evaluated should be false.
        let evaluated = router.evaluateURL(NSURL(string: "scheme://tabTwo:5150/foo/bar/tabTwo?a=b&b=c")!)
        
        waitForExpectationsWithTimeout(2.0) { error in
            XCTAssertNotNil(router.navigator)
            XCTAssertEqual(tabBarController.selectedIndex, 0)
            XCTAssertEqual(router.navigator!.selectedIndex, 0)
            XCTAssertFalse(evaluated)
        }
    }
}*/
