//
//  LocationVM.swift
//  FourSquare
//
//  Created by Mark Christian Buot on 31/01/2019.
//  Copyright © 2019 Mark Christian Buot. All rights reserved.
//

import Foundation
import MapKit

struct LocationAction: ReduxAction {
    
    var value: Location!
    var authorized: Bool!
}

struct LocationState: ReduxState {
    var value: [FoursquareLocation]!
    var authorized: Bool!
    var viewState: ViewState!
}

class LocationVM: BaseVM, CLLocationManagerDelegate {
    
    private var store: Store!
    private var repository: LocationRepository!
    private var venues: [FoursquareLocation] = []
    
    private let locationManager = CLLocationManager()
    private let geoCoder = CLGeocoder()
    
    override init() {
        super.init()
        self.store = Store(reducer: reducer, state: nil)
        
        self.repository = LocationRepository()
    }

    private func reducer(_ action: Action,
                         _ state: State?,
                         _ completion: @escaping ((State) -> Void)) {
        
        var state = LocationState()

        if let action = action as? LocationAction {
            state.authorized = action.authorized

            if let location = action.value {
                
                if state.viewState != .loading(nil) {
                    state.viewState = .loading(nil)
                    
                    completion(state)
                    self.repository.getVenues(location: location, onSuccess: { (venues) in
                        state.viewState = .success(nil)
                        self.venues = venues
                        completion(state)
                    }, onError: { error in
                        state.viewState = .error(error.localizedDescription)
                        completion(state)
                    })
                }
                
                return
            }
            
            completion(state)
        }
    }
    
    public func subscribe(_ subscriber: StoreSubscriber) {
        
        store?.subscribe(subscriber)
    }
    
    public func getState() -> ViewState? {
        guard let state = store?.getState() else { return nil }
        
        return state.viewState
    }

    public func getVenuesCount() -> Int {
        
        return venues.count
    }
    
    public func getVenue(at index: Int) -> FoursquareLocation? {
        guard index < venues.count else { return nil }
        
        return venues[index]
    }
    
    public func getVenueName(at index: Int) -> String? {
        guard index < venues.count else { return nil }
        
        return venues[index].name
    }
    
    public func getVenueDistance(at index: Int) -> String? {
        guard index < venues.count else { return nil }
        
        return venues[index].distance + " meters"
    }
    
    public func loadDefaultLocations() {
        locationManager.delegate = self
        
        var action = LocationAction()
        
        Permissions.isLocationServiceAuthorized { (authorization) in
            switch authorization {
            case .authorized:
                action.authorized = true
                self.locationManager.startUpdatingLocation()
            case .rejected:
                action.authorized = false
                break
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            }
            
            self.store.dispatch(action: action)
        }
    }
    
    //MARK: CLLocation Manager delegate
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        
        var action = LocationAction()

        switch status {
            
        case .authorizedWhenInUse: fallthrough
        case .authorizedAlways:
            action.authorized = true
            locationManager.startUpdatingLocation()
        case .denied: fallthrough
        case .restricted:
            action.authorized = false
        case .notDetermined: break
        }
        
        self.store.dispatch(action: action)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        
        print("Error code: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else { return }
        
        locationManager.stopUpdatingLocation()
        
        
        var action = LocationAction()
        
        action.authorized = true
        action.value = Location(id: UUID().uuidString,
                                lat: String(location.coordinate.latitude),
                                lng: String(location.coordinate.longitude))
        
        store.dispatch(action: action)
    }
}
