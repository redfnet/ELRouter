//
//  RouteTests.swift
//  THGRouter
//
//  Created by Angelo Di Paolo on 12/09/15.
//  Copyright © 2015 theholygrail.io. All rights reserved.
//

import XCTest
@testable import THGRouter

// MARK: - initialization Tests

class RouteTests: XCTestCase {
    func test_initialization_withName() {
        let route = Route("testName", type: .Other)
        
        XCTAssertNotNil(route.name)
        XCTAssertEqual(route.name, "testName")
        XCTAssertEqual(route.type, RoutingType.Other)
        XCTAssertNil(route.parentRoute)
        XCTAssertNil(route.parentRouter)
        XCTAssertNil(route.action)
        XCTAssertTrue(route.userInfo.isEmpty)
        XCTAssertTrue(route.subRoutes.isEmpty)
    }
    
    func test_initialization_withNameAndAction() {
        let route = Route("testName", type: .Other) { _ in
            return nil
        }
        
        XCTAssertNotNil(route.name)
        XCTAssertEqual(route.name, "testName")
        XCTAssertEqual(route.type, RoutingType.Other)
        XCTAssertNil(route.parentRoute)
        XCTAssertNil(route.parentRouter)
        XCTAssertNotNil(route.action)
        XCTAssertTrue(route.userInfo.isEmpty)
        XCTAssertTrue(route.subRoutes.isEmpty)
    }
    
    func test_initialization_withoutName() {
        let parentRoute = Route("parent", type: .Other)
        let route = Route(type: .Other, parentRoute: parentRoute)
        
        XCTAssertNil(route.name)
        XCTAssertEqual(route.type, RoutingType.Other)
        XCTAssertNotNil(route.parentRoute)
        XCTAssertEqual(route.parentRoute, parentRoute)
        XCTAssertNil(route.parentRouter)
        XCTAssertNil(route.action)
        XCTAssertTrue(route.userInfo.isEmpty)
        XCTAssertTrue(route.subRoutes.isEmpty)
    }
    
    func test_initialization_withTypeAndAction() {
        let parentRoute = Route("parent", type: .Other)
        let route = Route(type: .Other, parentRoute: parentRoute) { _ in
            return nil
        }
        
        XCTAssertNil(route.name)
        XCTAssertEqual(route.type, RoutingType.Other)
        XCTAssertNotNil(route.parentRoute)
        XCTAssertEqual(route.parentRoute, parentRoute)
        XCTAssertNil(route.parentRouter)
        XCTAssertNotNil(route.action)
        XCTAssertTrue(route.userInfo.isEmpty)
        XCTAssertTrue(route.subRoutes.isEmpty)
    }
    
    func test_initialization_withNamedAndParentRoute() {
        let parentRoute = Route("parent", type: .Other)
        let route = Route("sub", type: .Other, parentRoute: parentRoute) { _ in
            return nil
        }
        
        XCTAssertNotNil(route.name)
        XCTAssertEqual(route.name, "sub")
        XCTAssertEqual(route.type, RoutingType.Other)
        XCTAssertNotNil(route.parentRoute)
        XCTAssertNil(route.parentRouter)
        XCTAssertNotNil(route.action)
        XCTAssertTrue(route.userInfo.isEmpty)
        XCTAssertTrue(route.subRoutes.isEmpty)
    }
}

// MARK: - variable Tests

extension RouteTests {
    func test_variable_appendsSubRoute() {
        let parentRoute = Route("variableTest", type: .Other)
        parentRoute.variable()
        
        XCTAssertFalse(parentRoute.subRoutes.isEmpty)
        XCTAssertEqual(parentRoute.subRoutes.count, 1)
    }
    
    func test_variable_returnsSubRoute() {
        let parentRoute = Route("variableTest", type: .Other)
        let variableRoute = parentRoute.variable()
        
        XCTAssertEqual(variableRoute.type, RoutingType.Variable)
    }
    
    func test_variable_setsParentRouter() {
        let router = Router()
        let parentRoute = Route("variableTest", type: .Other)
        parentRoute.parentRouter = router
        
        parentRoute.variable()
        XCTAssertEqual(parentRoute.subRoutes[0].parentRouter, router)
    }
    
    func test_variable_setsParentRoute() {
        let parentRoute = Route("variableTest", type: .Other)
        
        parentRoute.variable()
        XCTAssertEqual(parentRoute.subRoutes[0].parentRoute, parentRoute)
    }
}

// MARK: - route Tests

extension RouteTests {
    func test_route_appendsSubRoute() {
        let parentRoute = Route("routeTest", type: .Other)
        parentRoute.route("sub", type: .Other)
        
        XCTAssertFalse(parentRoute.subRoutes.isEmpty)
        XCTAssertEqual(parentRoute.subRoutes.count, 1)
    }
    
    func test_route_returnsSubRoute() {
        let parentRoute = Route("routeTest", type: .Other)
        let subRoute = parentRoute.route("sub", type: .Other)
        
        XCTAssertEqual(subRoute.name, "sub")
        XCTAssertEqual(subRoute.type, RoutingType.Other)
    }
    
    func test_route_setsParentRouter() {
        let router = Router()
        let parentRoute = Route("routeTest", type: .Other)
        parentRoute.parentRouter = router
        
        parentRoute.route("sub", type: .Other)
        XCTAssertEqual(parentRoute.subRoutes[0].parentRouter, router)
    }
    
    func test_route_setsParentRoute() {
        let parentRoute = Route("variableTest", type: .Other)
        
        parentRoute.route("sub", type: .Other)
        XCTAssertEqual(parentRoute.subRoutes[0].parentRoute, parentRoute)
    }
}

// MARK: - execute Tests

extension RouteTests {
    func test_execute_returnsActionResult() {
        let route = Route("executeTest", type: .Other) { variable in
            return "foo"
        }
        
        let result = route.execute(false)
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result is String)
        XCTAssertEqual(result as? String, "foo")
    }
    
    func test_execute_passesVariableToActionClosure() {
        let route = Route("executeTest", type:  .Static) { variable in
            XCTAssertNotNil(variable)
            XCTAssertEqual(variable, "foo")
            return nil
        }
        
        route.execute(false, variable: "foo")
    }
    
    func test_execute_pushesViewController() {
        let router = Router()
        let navigator = TestNavigator()
        router.navigator = navigator
        let route = Route("executeTest", type:  .Push) { variable in
            let vc = UIViewController(nibName: nil, bundle: nil)
            vc.title = "Push Test"
            return vc
        }
        route.parentRouter = router
        
        route.execute(false)
        
        XCTAssertEqual(navigator.testNavigationController?.viewControllers.count, 2)
        XCTAssertEqual(navigator.testNavigationController?.topViewController?.title, "Push Test")
    }
    
    func test_execute_presentsModalViewController() {
        let router = Router()
        let navigator = TestNavigator()
        router.navigator = navigator
        let route = Route("executeTest", type:  .Modal) { variable in
            let vc = UIViewController(nibName: nil, bundle: nil)
            vc.title = "Modal Test"
            return vc
        }
        route.parentRouter = router
        
        route.execute(false)
        
        XCTAssertEqual(navigator.testNavigationController?.viewControllers.count, 1)
        XCTAssertNotNil(navigator.testNavigationController?.topViewController?.presentedViewController)
        XCTAssertEqual(navigator.testNavigationController?.topViewController?.presentedViewController?.title, "Modal Test")
    }
    
    func test_execute_setsStaticValue() {
        XCTFail()
    }
    
    func test_execute_performsSegue() {
        XCTFail()
    }
}

// MARK: - routesForComponents Tests

extension RouteTests {
    func test_routesForComponents_returnsEmptyResultsForBogusComponents() {
        let route = Route("variableTest", type: .Other)
        let results = route.routesForComponents(["walmart.com", "foo"])
        XCTAssertTrue(results.isEmpty)
    }
    
    func test_routesForComponents_returnsEmptyResultsForEmptyComponents() {
        let route = Route("variableTest", type: .Other)
        let results = route.routesForComponents([])
        XCTAssertTrue(results.isEmpty)
    }
    
    func test_routesForComponents_returnsNamedRoutesForValidComponents() {
        let route = Route("variableTest", type: .Other)
        route.route("walmart.com", type: .Other).route("foo", type: .Other)
        
        let results = route.routesForComponents(["walmart.com", "foo"])
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "walmart.com")
        XCTAssertEqual(results[1].name, "foo")
    }
    
    func test_routesForComponents_returnsVariableRoutesWhenNextComponentExists() {
        let route = Route("variableTest", type: .Other)
        route.route("walmart.com", type: .Other).variable().route("foo", type: .Other)
        
        let results = route.routesForComponents(["walmart.com", "12345", "foo"])
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].name, "walmart.com")
        XCTAssertEqual(results[1].type, RoutingType.Variable)
        XCTAssertEqual(results[2].name, "foo")
    }
    
    func test_routesForComponents_returnsVariableRoutesWhenNextComponentIsMissing() {
        let route = Route("variableTest", type: .Other)
        route.route("walmart.com", type: .Other).variable().route("foo", type: .Other)
        
        let results = route.routesForComponents(["walmart.com", "12345"])
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "walmart.com")
        XCTAssertEqual(results[1].type, RoutingType.Variable)
    }
}

// MARK: - routesByName Tests

extension RouteTests {
    func test_routesByName_returnsRoutesForValidName() {
        let testName = "subRouteName"
        let route = Route("routesByName", type: .Other)
        route.variable()
        route.route(testName, type: .Other)
        route.route(testName, type: .Static)
        
        let namedRoutes = route.routesByName("subRouteName")
        XCTAssertFalse(namedRoutes.isEmpty)
        XCTAssertEqual(namedRoutes.count, 2)
        
        for route in namedRoutes {
            XCTAssertNotNil(route.name)
            XCTAssertEqual(route.name, testName)
        }
    }
    
    func test_routesByName_returnsEmptyArrayForBogusName() {
        let testName = "subRouteName"
        let route = Route("routesByName", type: .Other)
        route.variable()
        route.route(testName, type: .Other)
        route.route(testName, type: .Static)
        
        let namedRoutes = route.routesByName("bogusName")
        XCTAssertTrue(namedRoutes.isEmpty)
    }
}

// MARK: - routesByType Tests

extension RouteTests {
    func test_routesByType_returnsRoutesForValidType() {
        let testName = "subRouteName"
        let route = Route("routesByName", type: .Other)
        route.variable()
        route.route(testName, type: .Static)
        route.route(testName, type: .Static)
        
        let filteredRoutes = route.routesByType(.Static)
        XCTAssertFalse(filteredRoutes.isEmpty)
        XCTAssertEqual(filteredRoutes.count, 2)
        
        for route in filteredRoutes {
            XCTAssertEqual(route.type, RoutingType.Static)
        }
    }
    
    func test_routesByType_returnsEmptyArrayForBogusType() {
        let testName = "subRouteName"
        let route = Route("routesByName", type: .Other)
        route.variable()
        route.route(testName, type: .Static)
        route.route(testName, type: .Static)
        
        let filteredRoutes = route.routesByType(.Other)
        XCTAssertTrue(filteredRoutes.isEmpty)
    }
}

@objc final class TestNavigator: NSObject, Navigator {
    var selectedViewController: UIViewController?
    var selectedIndex: Int = 0
    var testNavigationController: UINavigationController?
    
    override init() {
        let navigationConroller = UINavigationController(rootViewController: UIViewController(nibName: nil, bundle: nil))
        testNavigationController = navigationConroller
        selectedViewController = navigationConroller
    }
    
    func setViewControllers(viewControllers: [UIViewController]?, animated: Bool) {
        
    }
}