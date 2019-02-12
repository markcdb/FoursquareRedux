//
//  Redux.swift
//  FourSquare
//
//  Created by Mark Christian Buot on 08/02/2019.
//  Copyright © 2019 Mark Christian Buot. All rights reserved.
//

import Foundation

protocol Action { }

protocol State {
    
    var viewState: ViewState! { get set }
}

typealias Reducer = (_ action: Action,
    _ state: State?,
    _ completion: @escaping ((State) -> Void)) -> Void

protocol StoreSubscriber {
    func newState(state: State)
}

class Store {
    let reducer: Reducer
    var state: State?
    var subscribers: [StoreSubscriber] = []
    
    init(reducer: @escaping Reducer, state: State?) {
        self.reducer = reducer
        self.state = state
    }
    
    func dispatch(action: Action) {
        reducer(action, state, {[weak self] newState in
            guard let self = self else { return }
            self.state = newState
            
            self.subscribers.forEach { $0.newState(state: self.state!) }
        })
    }
    
    func subscribe(_ newSubscriber: StoreSubscriber) {
        subscribers.append(newSubscriber)
    }
    
    func getState() -> State? {
        return self.state
    }
}
