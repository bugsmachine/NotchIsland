//
//  FileActions.swift
//  NotchIsland
//
//  Created by 曹丁杰 on 2024/8/7.
//
import Cocoa
import Foundation
import CommonCrypto
import Alamofire


struct Chunk {
    let index: Int
    let data: Data
    let hash: String
}

func splitFileAndCalculateHashes(fileURL: URL, chunkSize: Int, completion: @escaping ([Chunk]) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let fileData = try Data(contentsOf: fileURL)
            var chunks: [Chunk] = []
            let totalChunks = Int(ceil(Double(fileData.count) / Double(chunkSize)))

            let dispatchGroup = DispatchGroup()
            let queue = DispatchQueue(label: "chunkProcessingQueue", attributes: .concurrent)
            
            for index in 0..<totalChunks {
                dispatchGroup.enter()
                queue.async {
                    let startIndex = index * chunkSize
                    let endIndex = min(startIndex + chunkSize, fileData.count)
                    let chunkData = fileData[startIndex..<endIndex]
                    let hash = md5Hash(data: chunkData)
                    let chunk = Chunk(index: index, data: chunkData, hash: hash)
                    chunks.append(chunk)
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.wait()
            DispatchQueue.main.async {
                completion(chunks)
            }
        } catch {
            print("Error reading file: \(error)")
        }
    }
}

func calculateFileHash(fileURL: URL, completion: @escaping (String?) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let fileData = try Data(contentsOf: fileURL)
            let hash = md5Hash(data: fileData)
            DispatchQueue.main.async {
                completion(hash)
            }
        } catch {
            print("Error reading file for hash: \(error)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}

func md5Hash(data: Data) -> String {
    var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &hash)
    }
    return hash.map { String(format: "%02x", $0) }.joined()
}



func uploadChunks(chunks: [Chunk], fileName: String, completion: @escaping (Bool) -> Void) {
    let dispatchGroup = DispatchGroup()
    var successCount = 0

    for chunk in chunks {
        dispatchGroup.enter()
        uploadChunk(chunk: chunk, fileName: fileName) { success in
            if success {
                successCount += 1
            }
            dispatchGroup.leave()
        }
    }

    dispatchGroup.notify(queue: .main) {
        completion(successCount == chunks.count)
    }
}

func uploadChunk(chunk: Chunk, fileName: String, completion: @escaping (Bool) -> Void) {
    let url = "http://localhost:8808/api/file/upload"
    let parameters: [String: Any] = [
        "hash": chunk.hash,
        "index": chunk.index,
        "filename": fileName
    ]

    AF.upload(multipartFormData: { multipartFormData in
        multipartFormData.append(chunk.data, withName: "file", fileName: fileName, mimeType: "application/octet-stream")
        for (key, value) in parameters {
            if let data = "\(value)".data(using: .utf8) {
                multipartFormData.append(data, withName: key)
            }
        }
    }, to: url).response { response in
        switch response.result {
        case .success:
            completion(true)
        case .failure(let error):
            print("Upload failed: \(error)")
            completion(false)
        }
    }
}

func uploadFile(fileURL: URL, chunkSize: Int, completion: @escaping (Bool) -> Void) {
    let fileName = fileURL.lastPathComponent

    splitFileAndCalculateHashes(fileURL: fileURL, chunkSize: chunkSize) { chunks in
        guard !chunks.isEmpty else {
            print("No chunks to upload")
            NSAlert.popError("No chunks to upload")
            completion(false)
            return
        }

        calculateFileHash(fileURL: fileURL) { fileHash in
            guard let fileHash = fileHash else {
                print("Failed to calculate file hash")
                NSAlert.popError("Failed to calculate file hash")
                completion(false)
                return
            }

            uploadChunks(chunks: chunks, fileName: fileName) { success in
                if success {
                    let userID = UserDefaults.standard.string(forKey: "userID") ?? ""
                    combineFile(fileName: fileName, totalChunks: chunks.count, fileHash: fileHash, userID: userID) { success in
                        if success {
                            print("File combined successfully on the server")
                            completion(true)
                        } else {
                            print("Failed to combine file on the server")
                            NSAlert.popError("Failed to combine file on the server")
                            completion(false)
                        }
                    }
                } else {
                    print("Failed to upload chunks")
                    NSAlert.popError("Failed to upload chunks")
                    completion(false)
                }
            }
        }
    }
}



func combineFile(fileName: String, totalChunks: Int, fileHash: String, userID: String, completion: @escaping (Bool) -> Void) {
    let url = "http://localhost:8808/api/file/combine"
    let parameters: [String: Any] = [
        "filename": fileName,
        "totalParts": totalChunks,
        "hash": fileHash,
        "userID": userID
    ]

    AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default).response { response in
        print("Combine response: \(response)")
        if let httpResponse = response.response {
            switch httpResponse.statusCode {
            case 200...299:
                print("Combine successful")
                completion(true)
            case 400:
                if let data = response.data,
                   let json = try? JSONSerialization.jsonObject(with: data, options: []),
                   let dict = json as? [String: Any],
                   let errorMessage = dict["error"] as? String {
                    print("Combine failed with status 400: \(errorMessage)")
                } else {
                    print("Combine failed with status 400 and no error message.")
                }
                completion(false)
            default:
                print("Combine failed with status \(httpResponse.statusCode): \(String(describing: response.error))")
                completion(false)
            }
        } else {
            print("Combine failed: \(String(describing: response.error))")
            completion(false)
        }
    }
}

func checkIfFileOnCloud(fileName: String, user: String, completion: @escaping (Bool) -> Void) {
    let url = "http://localhost:8808/api/file/check"
    let parameters: [String: Any] = [
        "name": fileName,
        "user": user
    ]

    AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default).response { response in
//        print("Check response: \(response)")
        if let httpResponse = response.response {
            switch httpResponse.statusCode {
            case 200:
//                print("File found on the server")
                completion(true)
            case 404:
                if let data = response.data,
                   let json = try? JSONSerialization.jsonObject(with: data, options: []),
                   let dict = json as? [String: Any],
                   let errorMessage = dict["error"] as? String {
//                    print("File not found on the server: \(errorMessage)")
                } else {
//                    print("File not found on the server and no error message.")
                }
                completion(false)
            default:
                print("Check failed with status \(httpResponse.statusCode): \(String(describing: response.error))")
                completion(false)
            }
        } else {
            print("Check failed: \(String(describing: response.error))")
            completion(false)
        }
    }
}
