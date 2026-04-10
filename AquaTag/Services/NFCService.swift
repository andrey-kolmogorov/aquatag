//
//  NFCService.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import CoreNFC

class NFCService: NSObject {
    enum NFCError: LocalizedError {
        case notSupported
        case scanCancelled
        case invalidTag
        case readFailed
        case writeFailed
        case noNDEFSupport
        
        var errorDescription: String? {
            switch self {
            case .notSupported:
                return "NFC is not supported on this device"
            case .scanCancelled:
                return "Scan was cancelled"
            case .invalidTag:
                return "Invalid NFC tag"
            case .readFailed:
                return "Failed to read NFC tag"
            case .writeFailed:
                return "Failed to write to NFC tag"
            case .noNDEFSupport:
                return "This tag doesn't support NDEF"
            }
        }
    }
    
    private var readSession: NFCNDEFReaderSession?
    private var readCompletion: ((Result<String, Error>) -> Void)?
    private var writeSession: NFCNDEFReaderSession?
    private var writeCompletion: ((Result<Void, Error>) -> Void)?
    private var plantIDToWrite: String?
    
    // MARK: - Check NFC Availability
    
    static func isNFCAvailable() -> Bool {
        return NFCNDEFReaderSession.readingAvailable
    }
    
    // MARK: - Read NFC Tag
    
    func readTag() async throws -> String {
        guard Self.isNFCAvailable() else {
            throw NFCError.notSupported
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            readCompletion = { result in
                continuation.resume(with: result)
            }
            
            readSession = NFCNDEFReaderSession(
                delegate: self,
                queue: nil,
                invalidateAfterFirstRead: true
            )
            readSession?.alertMessage = "Hold near plant tag to log watering"
            readSession?.begin()
        }
    }
    
    // MARK: - Write NFC Tag
    
    func writeTag(plantID: String) async throws {
        guard Self.isNFCAvailable() else {
            throw NFCError.notSupported
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            plantIDToWrite = plantID
            writeCompletion = { result in
                continuation.resume(with: result)
            }
            
            writeSession = NFCNDEFReaderSession(
                delegate: self,
                queue: nil,
                invalidateAfterFirstRead: false
            )
            writeSession?.alertMessage = "Hold near blank NFC tag to write plant ID"
            writeSession?.begin()
        }
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension NFCService: NFCNDEFReaderSessionDelegate {
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetectNDEFs messages: [NFCNDEFMessage]
    ) {
        // This method is called for read operations
        guard let message = messages.first,
              let record = message.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            readCompletion?(.failure(NFCError.invalidTag))
            return
        }
        
        // NDEF Text records have a language code prefix (usually 2 bytes)
        // Format: [status byte][language code][text]
        // We need to skip the language code prefix
        var plantID = payload
        if let firstChar = payload.first,
           firstChar.isASCII,
           !firstChar.isLetter {
            // Skip status byte and language code (typically "en")
            let dropCount = 1 + 2 // status byte + "en"
            plantID = String(payload.dropFirst(dropCount))
        }
        
        readCompletion?(.success(plantID))
    }
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetect tags: [NFCNDEFTag]
    ) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected")
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                self.handleError(error)
                return
            }
            
            // Determine if this is a read or write operation
            if self.plantIDToWrite != nil {
                self.performWrite(tag: tag, session: session)
            } else {
                self.performRead(tag: tag, session: session)
            }
        }
    }
    
    private func performRead(tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        tag.queryNDEFStatus { status, _, error in
            if let error = error {
                session.invalidate(errorMessage: "Query failed: \(error.localizedDescription)")
                let completion = self.readCompletion
                self.readCompletion = nil
                completion?(.failure(error))
                return
            }
            
            guard status != .notSupported else {
                session.invalidate(errorMessage: "Tag doesn't support NDEF")
                let completion = self.readCompletion
                self.readCompletion = nil
                completion?(.failure(NFCError.noNDEFSupport))
                return
            }
            
            tag.readNDEF { message, error in
                if let error = error {
                    session.invalidate(errorMessage: "Read failed")
                    let completion = self.readCompletion
                    self.readCompletion = nil
                    completion?(.failure(error))
                    return
                }

                guard let message = message,
                      let record = message.records.first else {
                    session.invalidate(errorMessage: "No data on tag")
                    let completion = self.readCompletion
                    self.readCompletion = nil
                    completion?(.failure(NFCError.invalidTag))
                    return
                }

                let payload = record.payload
                print("📡 NFC Raw payload bytes: \(payload.map { String(format: "%02x", $0) }.joined(separator: " "))")
                print("📡 NFC Record TNF: \(record.typeNameFormat.rawValue), type: \(String(data: record.type, encoding: .utf8) ?? "?")")

                var plantID = ""

                // Handle URI records (new format: aquatag://water/{plantID})
                if record.typeNameFormat == .nfcWellKnown,
                   let type = String(data: record.type, encoding: .utf8), type == "U" {
                    if let uri = record.wellKnownTypeURIPayload()?.absoluteString {
                        print("📡 URI record: \(uri)")
                        // Parse aquatag://water/{plantID}
                        if uri.hasPrefix("aquatag://water/") {
                            plantID = String(uri.dropFirst("aquatag://water/".count))
                        }
                    }
                }

                // Handle Text records (legacy format: aquatag:{plantID})
                if plantID.isEmpty,
                   record.typeNameFormat == .nfcWellKnown,
                   let type = String(data: record.type, encoding: .utf8), type == "T" {
                    if payload.count > 3 {
                        let statusByte = payload[0]
                        let isUTF16 = (statusByte & 0x80) != 0
                        let languageCodeLength = Int(statusByte & 0x3F)
                        let textStart = 1 + languageCodeLength

                        guard textStart < payload.count else {
                            print("⚠️ Invalid payload: not enough data")
                            session.invalidate(errorMessage: "Invalid tag data")
                            self.readCompletion?(.failure(NFCError.invalidTag))
                            return
                        }

                        let textData = payload.dropFirst(textStart)

                        if isUTF16 {
                            print("📡 Detected UTF-16 encoding")
                            var dataToConvert = Data(textData)
                            var encoding: String.Encoding = .utf16LittleEndian

                            if dataToConvert.count >= 2 {
                                let first = dataToConvert[0]
                                let second = dataToConvert[1]
                                if first == 0xFF && second == 0xFE {
                                    print("📡 BOM detected: Little-endian")
                                    encoding = .utf16LittleEndian
                                    dataToConvert = dataToConvert.dropFirst(2)
                                } else if first == 0xFE && second == 0xFF {
                                    print("📡 BOM detected: Big-endian")
                                    encoding = .utf16BigEndian
                                    dataToConvert = dataToConvert.dropFirst(2)
                                }
                            }
                            plantID = String(data: dataToConvert, encoding: encoding) ?? ""
                        } else {
                            print("📡 Detected UTF-8 encoding")
                            plantID = String(data: textData, encoding: .utf8) ?? ""
                        }
                    }
                }

                print("📡 NFC Parsed plant ID: '\(plantID)'")

                guard !plantID.isEmpty else {
                    print("⚠️ Empty plant ID after parsing")
                    session.invalidate(errorMessage: "Could not read tag data")
                    let completion = self.readCompletion
                    self.readCompletion = nil
                    completion?(.failure(NFCError.invalidTag))
                    return
                }

                session.alertMessage = "✅ Tag read successfully!"
                session.invalidate()
                let completion = self.readCompletion
                self.readCompletion = nil
                completion?(.success(plantID))
            }
        }
    }
    
    private func performWrite(tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        guard let plantID = plantIDToWrite else {
            session.invalidate(errorMessage: "No plant ID to write")
            let completion = self.writeCompletion
            self.writeCompletion = nil
            self.plantIDToWrite = nil
            completion?(.failure(NFCError.writeFailed))
            return
        }
        
        tag.queryNDEFStatus { status, capacity, error in
            if let error = error {
                session.invalidate(errorMessage: "Query failed")
                let completion = self.writeCompletion
                self.writeCompletion = nil
                self.plantIDToWrite = nil
                completion?(.failure(error))
                return
            }
            
            guard status == .readWrite else {
                session.invalidate(errorMessage: "Tag is not writable")
                let completion = self.writeCompletion
                self.writeCompletion = nil
                self.plantIDToWrite = nil
                completion?(.failure(NFCError.writeFailed))
                return
            }
            
            // Create NDEF message with URI record for background tag reading
            // Format: aquatag://water/{plantID}
            let urlString = "aquatag://water/\(plantID)"
            guard let url = URL(string: urlString),
                  let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else {
                session.invalidate(errorMessage: "Failed to create payload")
                let completion = self.writeCompletion
                self.writeCompletion = nil
                self.plantIDToWrite = nil
                completion?(.failure(NFCError.writeFailed))
                return
            }

            let message = NFCNDEFMessage(records: [urlPayload])
            
            tag.writeNDEF(message) { error in
                if let error = error {
                    session.invalidate(errorMessage: "Write failed")
                    let completion = self.writeCompletion
                    self.writeCompletion = nil
                    self.plantIDToWrite = nil
                    completion?(.failure(error))
                    return
                }
                
                session.alertMessage = "✅ Tag written successfully!"
                session.invalidate()
                let completion = self.writeCompletion
                self.writeCompletion = nil
                self.plantIDToWrite = nil
                completion?(.success(()))
            }
        }
    }
    
    private func handleError(_ error: Error) {
        if writeCompletion != nil {
            writeCompletion?(.failure(error))
            plantIDToWrite = nil
        } else {
            readCompletion?(.failure(error))
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session is now active
    }
    
    func readerSession(
        _ session: NFCNDEFReaderSession,
        didInvalidateWithError error: Error
    ) {
        // Check if user cancelled
        if let readerError = error as? NFCReaderError {
            if readerError.code == .readerSessionInvalidationErrorUserCanceled {
                if readCompletion != nil {
                    let completion = readCompletion
                    readCompletion = nil
                    completion?(.failure(NFCError.scanCancelled))
                } else if writeCompletion != nil {
                    let completion = writeCompletion
                    writeCompletion = nil
                    plantIDToWrite = nil
                    completion?(.failure(NFCError.scanCancelled))
                }
                return
            }
        }
        
        // Only call completion if there was an actual error
        // (not just normal session invalidation after success)
        // Code 200 means "session invalidated successfully" (not an error)
        if (error as NSError).code != 200 {
            // Only resume if completion hasn't been called yet
            if readCompletion != nil {
                let completion = readCompletion
                readCompletion = nil
                completion?(.failure(error))
            } else if writeCompletion != nil {
                let completion = writeCompletion
                writeCompletion = nil
                plantIDToWrite = nil
                completion?(.failure(error))
            }
        } else {
            // Success invalidation - just clean up
            readCompletion = nil
            writeCompletion = nil
            plantIDToWrite = nil
        }
    }
}
