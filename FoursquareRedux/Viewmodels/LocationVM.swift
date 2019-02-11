//
//  LocationVM.swift
//  FourSquare
//
//  Created by Mark Christian Buot on 31/01/2019.
//  Copyright © 2019 Mark Christian Buot. All rights reserved.
//

import Foundation
import MapKit

protocol LocationVMDelegate: class {
    func locationVM(_ vm: LocationVM,
                    viewStateChanged state: ViewState,
                    message msg: String?)
    
    func locationVmLocationUpdateFailed(_ vm: LocationVM)
}

class LocationVM: BaseVM<[FoursquareLocation]>, CLLocationManagerDelegate {
    
    private var repository: LocationRepository!
    private var venues: [FoursquareLocation] = []
    private var location: Location!
    private var authorized: Bool = true
    
    private let locationManager = CLLocationManager()
    private let geoCoder = CLGeocoder()
    
    weak public var delegate: LocationVMDelegate?
    
    override var state: ReduxState<[FoursquareLocation]>! {
        didSet {
            let message = state.state.getString()
            
            self.delegate?.locationVM(self,
                                      viewStateChanged: state.state,
                                      message: message)
        }
    }
    
    init(delegate: LocationVMDelegate) {
        super.init()
        self.repository = LocationRepository()
        self.delegate = delegate
    }

    public func getVenues() {
        
        state.state = .loading(nil)
        
        repository.getVenues(location: self.location,
                             onSuccess: {[weak self] venues in
                                guard let self = self else { return }
                                
                                self.venues = venues
                                self.state.state = .success(nil)

        }) {[weak self] error in
            guard let self = self else { return }
            
            self.state.state = .error(error.localizedDescription)
        }
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
    
    public func getState() -> ViewState? {
        
        return state.state
    }
    
    public func getLocationAuthorization() -> Bool {
        
        return authorized
    }
    
    public func loadDefaultLocations() {
        locationManager.delegate = self
        
        Permissions.isLocationServiceAuthorized { (authorization) in
            switch authorization {
            case .authorized:
                self.authorized = true
                self.locationManager.startUpdatingLocation()
            case .rejected:
                self.authorized = false
                self.delegate?.locationVmLocationUpdateFailed(self)
                break
            case .notDetermined:
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    //MARK: CLLocation Manager delegate
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
            
        case .authorizedWhenInUse: fallthrough
        case .authorizedAlways:
            authorized = true
            locationManager.startUpdatingLocation()
        case .denied: fallthrough
        case .restricted:
            authorized = false
            delegate?.locationVmLocationUpdateFailed(self)
        case .notDetermined: break
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        
        print("Error code: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.first else { return }
        
        locationManager.stopUpdatingLocation()
        
        self.location = Location(id: UUID().uuidString,
                                 lat: String(location.coordinate.latitude),
                                 lng: String(location.coordinate.longitude))
        
        
        if state.state == nil ||
            state.state != .loading(nil) {
            getVenues()
        }
    }
}
