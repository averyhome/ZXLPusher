//
//  Codable.swift
//  Deer
//
//  Created by Sven on 2019/11/6.
//  Copyright © 2019 zhuxiaoliang. All rights reserved.
//

import Foundation

extension String  {
    public func toDic() -> [String: Any]? {
        guard let jsonData:Data = self.data(using: .utf8) else {
            return nil
        }
        if let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) {
            return dict as? [String : Any] ?? nil
        }
        return nil
    }
}

//MARK Codable默认实现  封装decode encode方法
extension Encodable {
    var jsonData: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    var jsonDic: [String: Any]? {
        return self.jsonStr?.toDic()
    }
    
    var jsonStr: String? {
        guard let data = self.jsonData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension Decodable {
    static func decodable(data: Data) -> Self? {

        do {
            let decoder = JSONDecoder()
//            自定义date解析
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            df.locale = Locale.current
            decoder.dateDecodingStrategy = .formatted(df)
            let me = try decoder.decode(Self.self, from: data)
            return me
        } catch let error {
            print("------------------------>")
            print("\(self)")
            print("\(error)")
            print("<************************")
 
            return nil
        }
    }
    
    static func decodable(_ json: String, using encoding: String.Encoding = .utf8) -> Self? {

        guard let data = json.data(using: encoding) else { return nil }
        return Self.decodable(data: data)
    }
    
    static func decodable(fromURL url: String) -> Self?  {
        guard let url = URL(string: url) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return Self.decodable(data: data)
    }
    
    
    static func decodable<T: Encodable>(_ dic: [String: T]) -> Self? {
        guard  let jsonStr = dic.jsonStr else {
            return nil
        }
        guard let jsonData = jsonStr.data(using: .utf8) else {
            return nil
        }
        return decodable(data: jsonData)
    }
}


// 全局处理 当服务端的类型动态变化时
extension KeyedDecodingContainer {

    public func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
        if let value = try? decode(type, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }
    
    
    public func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? {
        if let value = try? decode(type, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key) {
            return Int(value)
        }
        return nil
    }
    
    public func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? {
        if let value = try? decode(type, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key) {
            return Double(value)
        }
        return nil
    }
    
    public func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? {
        if let value = try? decode(type, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return value == 1
        }
        if let value = try? decode(Double.self, forKey: key) {
            return Int(value) == 1
        }
        return nil
    }
    
    
    
    /// Avoid the failure just when decoding type of Dictionary, Array, SubModel failed
    public func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T : Decodable {
        return try? decode(type, forKey: key)
    }

}



