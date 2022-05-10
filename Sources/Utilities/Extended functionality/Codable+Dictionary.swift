//
//  File.swift
//  
//
//  Created by Johan Nyman on 2022-03-13.
//

import Foundation

//https://stackoverflow.com/questions/45209743/how-can-i-use-swift-s-codable-to-encode-into-a-dictionary/46329055#46329055
public extension Encodable {
    func asDictionary() -> [String: Any] {
        do {
            let data = try JSONEncoder().encode(self)
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                throw NSError()
            }
            return dictionary
        } catch {
            Log.error(error, message: "Unable to create dictionary from Encodable", in: .functionality)
        }
        return [String: Any]()
    }
}

//https://stackoverflow.com/questions/46327302/init-an-object-conforming-to-codable-with-a-dictionary-array/46327303#46327303
public extension Decodable {
    init(fromJSONDict: Any) {
        do {
            let data = try JSONSerialization.data(withJSONObject: fromJSONDict, options: .prettyPrinted)
            let decoder = JSONDecoder()
            self = try decoder.decode(Self.self, from: data)
        } catch {
            Log.error(error, message: "Unable to initialize \(Self.self) from dictionary", in: .functionality)
            fatalError()
        }
    }
}
