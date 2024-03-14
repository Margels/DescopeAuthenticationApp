//
//  Constants.swift
//  DescopeAuthenticationApp
//
//  Created by Margels on 05/03/24.
//

import Foundation
import UIKit

class Constants {
    
    let baseUrl = "<YOUR_BASE_URL>"
    let getUserInfo = "/get-Descope-User-Information"
    
    static let shared = Constants()
    
    func getUserInformation(with token: String, completion: @escaping ((UserInfoResponse?) -> ()?)) {
        
        guard let url = URL(string: "\(baseUrl)\(getUserInfo)") else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode)
            else {
                print("Invalid Response")
                return
            }
            
            guard let responseData = data else { return }
            
            let decoder = JSONDecoder()
            do {
                let userInfoResponse = try decoder.decode(UserInfoResponse.self, from: responseData)
                completion(userInfoResponse)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
        
    
}

struct UserInfoResponse: Decodable {
    let sub: String?
    let roles: [String]?
    var amr: [String]?
    let permissions: [String]?
    let nsec: [String: String]?
}
