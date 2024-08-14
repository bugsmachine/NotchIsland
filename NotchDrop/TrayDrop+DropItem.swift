import Foundation
import Cocoa
import QuickLook

extension TrayDrop {
    class DropItem: Identifiable, Codable, ObservableObject, Hashable {
        let id: UUID
        let fileName: String
        let size: Int
        let copiedDate: Date
        let workspacePreviewImageData: Data

        @Published var state: State

        enum State: Int, Codable {
            case idle
            case uploading
            case uploaded
            case error
            case notInLocal
            case notInCloud
        }

        init(url: URL) throws {
            state = .idle
            id = UUID()
            fileName = url.lastPathComponent
            size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            copiedDate = Date()
            workspacePreviewImageData = url.snapshotPreview().pngRepresentation

            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            print("Copying file to: \(storageURL.path)")
            try FileManager.default.copyItem(at: url, to: storageURL)

            let user_id = UserDefaults.standard.string(forKey: "userID") ?? ""
            if user_id != "" {
                state = .uploading
                uploadFile(fileURL: storageURL, chunkSize: 1024 * 1024 * 5) { is_success in
                    DispatchQueue.main.async {
                                        if is_success {
                                            print("File upload successful")
                                            self.state = .uploaded
                                        } else {
                                            self.state = .error
                                            print("File upload failed")
                                        }
                                    }
                }
            }
        }
        
        
        

        // MARK: - Hashable Conformance

        static func == (lhs: DropItem, rhs: DropItem) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        // MARK: - Codable Conformance

        enum CodingKeys: String, CodingKey {
            case id
            case fileName
            case size
            case copiedDate
            case workspacePreviewImageData
            case state
        }

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            fileName = try container.decode(String.self, forKey: .fileName)
            size = try container.decode(Int.self, forKey: .size)
            copiedDate = try container.decode(Date.self, forKey: .copiedDate)
            workspacePreviewImageData = try container.decode(Data.self, forKey: .workspacePreviewImageData)
            state = try container.decode(State.self, forKey: .state)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(fileName, forKey: .fileName)
            try container.encode(size, forKey: .size)
            try container.encode(copiedDate, forKey: .copiedDate)
            try container.encode(workspacePreviewImageData, forKey: .workspacePreviewImageData)
            try container.encode(state, forKey: .state)
        }
    }
}

extension TrayDrop.DropItem {
    static let mainDir = "CopiedItems"

    var storageURL: URL {
        documentsDirectory
            .appendingPathComponent(Self.mainDir)
            .appendingPathComponent(id.uuidString)
            .appendingPathComponent(fileName)
    }

    var workspacePreviewImage: NSImage {
        .init(data: workspacePreviewImageData) ?? .init()
    }

    var shouldClean: Bool {
        if !FileManager.default.fileExists(atPath: storageURL.path) { return true }
        if Date().timeIntervalSince(copiedDate) > TrayDrop.keepInterval { return true }
        return false
    }
}
