//
//  TestioNetworkService.swift
//  Testio
//
//  Created by Mindaugas on 26/07/2018.
//  Copyright © 2018 Mindaugas Jucius. All rights reserved.
//

import UIKit

enum Result<Value, Error: Swift.Error> {
    case success(Value)
    case failure(Error)
}

private let TestioAPIURLStringFormat = "http://playground.tesonet.lt/v1/%@"

private enum TestioEndpoint: String {
    case tokens
    case servers
}

protocol ServersRetrievingType {
    
}

typealias AuthenticationHandler = (Result<TestioToken, TestioError>) -> ()

protocol AuthorizationPerformingType {

    func authenticate(user: TestioUser, handler: @escaping AuthenticationHandler)
    
}

class TestioNetworkService: AuthorizationPerformingType, ServersRetrievingType {

    private var acceptableStatusCodes: Range<Int> { return 200..<300 }
    
    func authenticate(user: TestioUser, handler: @escaping AuthenticationHandler) {

        let endpointString = String.init(format: TestioAPIURLStringFormat, TestioEndpoint.tokens.rawValue)
        
        guard let encodedCredentials = try? user.encode(),
            let endpointURL = URL(string: endpointString) else {
            handler(.failure(.unknown(nil)))
            return
        }
        
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.httpBody = encodedCredentials
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let authenticationTask = session.dataTask(with: request) { data, response, error in
            
            if let error = error {
                handler(.failure(.unknown(error.localizedDescription)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                handler(.failure(.unknown(nil)))
                return
            }
            
            guard self.acceptableStatusCodes ~= httpResponse.statusCode else {
                let customError = TestioError.error(forStatusCode: httpResponse.statusCode)
                handler(.failure(customError))
                return
            }
            
            guard let data = data,
                let token = try? TestioToken.decode(fromData: data) else {
                handler(.failure(.unknown(nil)))
                return
            }
            
            handler(.success(token))
        }
        
        authenticationTask.resume()
    }
    
}
