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
            //Encode to data and then JSON-serialize to dictionary
            guard let data = self.asJSONData(),
                  !data.isEmpty,
                  let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw NSError()
            }
            return dictionary
        } catch {
            Log.error(error, message: "Unable to create dictionary from \(self)", in: .functionality)
        }
        return [String: Any]()
    }
    
    func asJSONData() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            return data
        } catch {
            Log.error(error, message: "Unable to data-serialize \(self)", in: .model)
        }
        return nil
    }
    
    func asJSONString() -> String? {
        return String(data: self.asJSONData() ?? Data(), encoding: .ascii)
    }
}

//https://stackoverflow.com/questions/46327302/init-an-object-conforming-to-codable-with-a-dictionary-array/46327303#46327303
public extension Decodable {
    init(fromJSONDict: Any) {
        guard JSONSerialization.isValidJSONObject(fromJSONDict) else {
            Log.fault(message: "Invalid JSON-object \(fromJSONDict)", in: .model)
            fatalError()
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: fromJSONDict, options: [.prettyPrinted])
            let decoder = JSONDecoder()
            self = try decoder.decode(Self.self, from: data)
        } catch {
            Log.error(error, message: "Unable to initialize \(Self.self) from dictionary: \n\(fromJSONDict)", in: .functionality)
            fatalError()
        }
    }
}
