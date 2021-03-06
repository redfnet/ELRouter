//
//  Router.swift
//  ELRouter
//
//  Created by Brandon Sneed on 10/15/15.
//  Copyright © 2015 Walmart. All rights reserved.
//

import Foundation
import ELFoundation
import ELDispatch

public typealias RouteCompletion = () -> Void

///
@objc
public class Router: NSObject {
    static public let sharedInstance = Router()
    public var navigator: Navigator? = nil
    
    public var routes: [Route] {
        return masterRoute.subRoutes
    }
    
    public weak var eventFirehose: RouterEventFirehose? {
        didSet {
            NavSync.sharedInstance.eventFirehose = eventFirehose
        }
    }
    
    private let masterRoute: Route = Route("MASTER", type: .Other)
    private var translation = [String : String]()

    public override init() {
        super.init()
        injectRouterSwizzles()
    }
}

// MARK: - Translation API

extension Router {
    public func translate(from: String, to: String) {
        let existing = translation[from]
        if existing != nil {
            exceptionFailure("A translation for \(from) exists already!")
        }
        
        translation[from] = to
    }
}

// MARK: - Managing the Navigator

extension Router {
    /// Attempt to detect what the navigator value should be.
    public func detectNavigator() {
        let windows = UIApplication.sharedApplication().windows
        for window in windows {
            if let nav = window.rootViewController as? Navigator {
                navigator = nav
                break
            }
        }
    }
    
    /// Update the view controllers that are managed by the navigator
    public func updateNavigator() {
        if navigator == nil {
            // try to detect the navigator if we don't have one.
            detectNavigator()
        }
        
        if let navigator = navigator {
            let navigatorRoutes = routesByType(.Static)
            var controllers = [UIViewController]()
            
            var associatedData: AssociatedData? = nil
            
            for route in navigatorRoutes {
                if let vc = route.execute(false, variable: nil, remainingComponents: [String](), associatedData: &associatedData) as? UINavigationController {
                    controllers.append(vc)
                }
            }
            
            // if we have controllers present already, add them to the beginning 
            // of the array.
            if let existingControllers = navigator.viewControllers {
                controllers.insertContentsOf(existingControllers, at: 0)
            }
            
            // set our new list.
            navigator.setViewControllers(controllers, animated: false)
        }
    }
}

// MARK: - Registering Routes

extension Router {
    /**
     Registers a top level route.
     
     - parameter route: The Route being registered.
    */
    public func register(route: Route) {
        var currentRoute = route
        
        // we may given the final link in a chain, walk back up to the top and
        // get the primary route to register.
        while currentRoute.parentRoute != nil {
            currentRoute.parentRouter = self
            currentRoute = currentRoute.parentRoute!
        }
        
        if currentRoute.name != nil {
            if routesByName(currentRoute.name!).count != 0 {
                let message = "A route already exists named \(currentRoute.name!)!"
                if isInUnitTest() {
                    exceptionFailure(message)
                } else {
                    assertionFailure(message)
                }
            }
            currentRoute.parentRouter = self
            masterRoute.subRoutes.append(currentRoute)
        }
    }
}

// MARK: - Evaluating Routes
extension Router {
    // This must not be used externally to determine if routes are processing
    // Due to threading, this may evaluate late compared in successive
    // execute commands due to thread switching to main on route evaluation
    // It is better to use the RouteCompletion block on the evaluate
    // function
    var processing: Bool {
        var result = false
        synchronized(self) { () -> Void in
            result = (Router.routesInFlight != nil)
        }
        return result
    }
    
    /**
     Evaluate a URL String. Routes matching the URL will be executed. This function
     is entended solely for externally-originating routes.
     
     - parameter url: The URL to evaluate.
     */
    public func evaluateURLString(urlString: String, animated: Bool = false, completion: RouteCompletion? = nil) -> Bool {
        guard let url = NSURL(string: urlString) else { return false }
        return evaluateURL(url, animated: animated, completion: completion)
    }
    
    /**
     Evaluate a URL. Routes matching the URL will be executed. This function
     is entended solely for externally-originating routes.

     - parameter url: The URL to evaluate.
    */
    public func evaluateURL(url: NSURL, associatedData: AssociatedData? = nil, animated: Bool = false, completion: RouteCompletion? = nil) -> Bool {
        guard let components = url.deepLinkComponents else { return false }
        var passedData: AssociatedData = url
        if let validAssociatedData = associatedData {
            passedData = validAssociatedData
        }
        return evaluate(components, associatedData: passedData, animated: animated, completion: completion)
    }

    /**
     Evaluate an array of RouteSpecs. Routes matching the specs will be executed.
     
     - parameter components: The array of specs to evaluate.
     - parameter animated: Determines if the view controller action should be animated.
     */
    public func evaluate(routes: [RouteEnum], animated: Bool = false, completion: RouteCompletion? = nil) -> Bool {
        return evaluate(routes, associatedData: nil, animated: animated, completion: completion)
    }
    
    /**
     Evaluate an array of RouteSpecs. Routes matching the specs will be executed.
     
     - parameter components: The array of components to evaluate.
     - parameter associatedData: Extra data that needs to be passed through to each block in the chain.
     - parameter animated: Determines if the view controller action should be animated.
     - parameter completion: closure to be called after evaluation.
     */
    public func evaluate(routes: [RouteEnum], associatedData: AssociatedData?, animated: Bool = false, completion: RouteCompletion? = nil) -> Bool {
        let components = componentsFromRoutes(routes)
        return evaluate(components, associatedData: associatedData, animated: animated, completion: completion)
    }

    /**
     Use to redirect from a currently executing route to another.  This should be called within one of your route handling blocks.

     - parameter components: The array of components to evaluate.
     - parameter associatedData: Extra data that needs to be passed through to each block in the chain.
     - parameter animated: Determines if the view controller action should be animated.
     - parameter completion: closure to be called after evaluation.
     */
    public func redirect(routes: [RouteEnum], associatedData: AssociatedData?, animated: Bool = false, completion: RouteCompletion? = nil) {
        synchronized(self) {
            Router.routesInFlight = nil
        }
        
        Dispatch().after(.Main, delay: 0.1) { 
            self.evaluate(routes, associatedData: associatedData, animated: animated, completion: completion)
        }
    }
}

// MARK: - Getting Routes

extension Router {
    /**
     Get the route for a particular RouteEnum
    
     - parameter routeEnum: The enum of the route to get
    */
    public func routeByEnum(routeEnum: RouteEnum) -> Route? {
        let filteredRoutes = routes.filterByName(routeEnum.spec.name)
        // Brandon's design is such that a route should only match 1
        if filteredRoutes.count == 1 {
            return filteredRoutes[0]
        }
        
        return nil
     }
    
    /**
     Get a route of a particular name.
     
     This function is marked internal to prevent API abuse
     
     - parameter name: The name of the routes to get.
    */
    internal func routeByName(name: String) -> Route? {
        return masterRoute.routeByName(name)
    }
    
    /**
     Get all routes matching a particular name.
     
     This function is marked internal to prevent API abuse
     
     - parameter name: The name of the routes to get.
     */
    internal func routesByName(name: String) -> [Route] {
        return routes.filterByName(name)
    }
    
    /**
     Get all routes of a particular routing type.
     
     - parameter type: The routing type of the routes to get.
    */
    public func routesByType(type: RoutingType) -> [Route] {
        return routes.filterByType(type)
    }
    
    /**
     Get all routes that match the given URL.
     
     - parameter url: The url to match against.
    */
    public func routesForURL(url: NSURL) -> [Route] {
        guard let components = url.deepLinkComponents else { return [Route]() }
        return routesForComponents(components)
    }
    
    /**
     Get all routes that match an array of components.
     
     - parameter components: The array of component strings to match against.
    */
    public func routesForComponents(components: [String]) -> [Route] {
        return masterRoute.routesForComponents(components)
    }
    
    internal func componentsFromRoutes(routes: [RouteEnum]) -> [String] {
        var components = [String]()
        for item in routes {
            components.append(item.spec.name)
        }
        return components
    }
}

// MARK: - Route/Navigation synchronization

extension Router {
    internal static let lock = Spinlock()
    
    // TODO: Consider making this a non-static, as it is fragile
    // If the thread processing the routes is killed (say a unit test terminates early)
    // then this static is never nilled out, and the processing computed variable
    // will always be true
    // I believe (this is a guess) that the author's intention was to make sure
    // that two routers could not execute routes at the same time
    // I suggest we find a more Swifty way to handle this concern
    private static var routesInFlight: [Route]? = nil
    
    // this function is for internal use and testability, DO NOT MAKE IT PUBLIC.
    internal func evaluate(components: [String], animated: Bool = false, completion: RouteCompletion? = nil) -> Bool {
        return evaluate(components, associatedData: nil, animated: animated, completion: completion)
    }

    // this function is for internal use and testability, DO NOT MAKE IT PUBLIC.
    internal func evaluate(components: [String], associatedData: AssociatedData?, animated: Bool = false, completion: RouteCompletion? = nil) -> Bool {
        var componentsWereHandled = false
        
        // if we have routes in flight, return false.  We can't do anything
        // until those have finished.
        if processing {
            log(.Debug, "Already processing route. Aborting.")
            return false
        }
        
        let routes = routesForComponents(components)
        let valid = routes.count == components.count
        
        var isRedirect = false
        if let last = routes.last where last.type == .Redirect {
            isRedirect = true
        }
        
        if (valid && routes.count > 0) || (isRedirect) {
            serializedRoute(routes, components: components, associatedData: associatedData, animated: animated, completion: completion)
            
            componentsWereHandled = true
        }
        
        return componentsWereHandled
    }
    
    private func nextVariable(components components: [String], routes: [Route], index: Int) -> String? {
        guard (components.count > index && routes.count > index && components.count == routes.count) else { return nil }
        
        let currentRoute = routes[index]
        
        if currentRoute.type == .Variable {
            return components[index]
        }
        
        if components.count > index + 1 {
            let nextRoute = routes[index + 1]
            if nextRoute.type == .Variable {
                return components[index + 1]
            }
        }
        
        return nil
    }
    
    internal func serializedRoute(routes: [Route], components: [String], associatedData: AssociatedData?, animated: Bool, completion: RouteCompletion? = nil) {
        if processing {
            log(.Debug, "Already processing route. Aborting.")
            return
        }
        
        var data: AssociatedData? = associatedData
        
        // set our in-flight routes to what we were given.
        synchronized(self) {
            Router.routesInFlight = routes
        }
        
        let navController = navigator?.selectedViewController as? UINavigationController
        // clear any presenting controllers.
        if let presentedViewController = navController?.topViewController?.presentedViewController {
            presentedViewController.dismissViewControllerAnimated(animated, completion: nil)
        }
        
        // process routes in the background.
        Dispatch().async(.Background) {
            var isRedirect = false
            
            for i in 0..<components.count {
                let route = routes[i]

                let variable = self.nextVariable(components: components, routes: routes, index: i)
                
                // acquire the lock.  if there's a nav event in progress
                // this will wait until that event has finished.
                Router.lock.lock()
                
                log(.Debug, "Processing route: \((route.name ?? variable)!), \(route.type.description)")
                
                var remainingComponents = [String]()
                if i + 1 < components.count {
                    remainingComponents = Array(components[i + 1..<components.count])
                }
                
                // execute route on the main thread.
                Dispatch().sync(.Main) {
                    let result = route.execute(animated, variable: variable, remainingComponents: remainingComponents, associatedData: &data)
                    log(.Debug, "Finished route: \((route.name ?? variable)!), \(route.type.description)")
                    if route.type == .Redirect {
                        if let redirectComponents = result as? [String] {
                            isRedirect = true
                            log(.Debug, "Redirecting to: \(redirectComponents.joinWithSeparator("/"))")
                            self.redirect(routeEnumsFromComponents(redirectComponents), associatedData: associatedData, animated: animated, completion: completion)
                        }
                    }
                }
                
                if isRedirect || self.processing == false {
                    // stop processing if it's a redirect.
                    break
                }
            }
            
            // clear our in-flight routes now that we're done.
            synchronized(self) {
                Router.routesInFlight = nil
            }
            
            // The completion block needs to run last, because
            // user code may trigger termination of the thread
            // If that happens, the static routesInFlight variable won't
            // be nilled out, and then all future routes will fail
            if isRedirect == false {
                // only run the completion if it's NOT a redirect.  the new route
                // we were redirected to will instead run the completion.
                completion?()
            }
            
        }
    }
}

