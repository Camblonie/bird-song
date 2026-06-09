//
//  BirdNETAPIService.swift
//  Bird Song
//
//  Sends a 3-second PCM buffer to a BirdNET-Analyzer server instance and
//  returns detected species with confidence scores.
//
//  The BirdNET-Analyzer server is self-hosted (free, open-source):
//    pip install birdnet bottle
//    python -m birdnet_analyzer.server --host 0.0.0.0 --port 8080
//
//  Server API:
//    POST multipart/form-data to <host>/analyze
//    Fields: "audio" (wav bytes), "meta" (JSON string)
//    Response: { "msg": "success", "results": [["Scientific_Common", 0.78], ...] }
//

import AVFoundation
import Foundation

/// A single raw result from the BirdNET server before catalog matching.
struct BirdNETResult {
    /// Full BirdNET label, e.g. "Turdus migratorius_American Robin"
    let label: String
    let confidence: Double
}

/// Handles communication with a BirdNET-Analyzer REST server.
final class BirdNETAPIService {

    // MARK: - Configuration

    /// Base URL of a running BirdNET-Analyzer server.
    /// Change to your server's IP/hostname for production use.
    /// Default points to localhost for development/testing.
    static let serverURL = URL(string: "http://localhost:8080")!

    /// Timeout for each analysis request in seconds.
    private static let requestTimeout: TimeInterval = 15

    // MARK: - Public API

    /// Encode the PCM buffer as WAV and POST it to the BirdNET server.
    /// Calls completion on a background thread with results or an error.
    static func analyze(
        buffer: AVAudioPCMBuffer,
        latitude: Double? = nil,
        longitude: Double? = nil,
        completion: @escaping (Result<[BirdNETResult], Error>) -> Void
    ) {
        // Encode PCM buffer → WAV bytes
        guard let wavData = encodeWAV(buffer: buffer) else {
            completion(.failure(APIError.encodingFailed))
            return
        }

        // Build multipart/form-data request
        let boundary = "BirdSong-\(UUID().uuidString)"
        var request = URLRequest(
            url: serverURL.appendingPathComponent("analyze"),
            timeoutInterval: requestTimeout
        )
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Build meta JSON field (lat/lon improve accuracy when provided)
        var metaDict: [String: Any] = ["contenttype": "audio/wav"]
        if let lat = latitude, let lon = longitude {
            metaDict["lat"] = lat
            metaDict["lon"] = lon
        }
        let metaJSON = (try? JSONSerialization.data(withJSONObject: metaDict))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        request.httpBody = buildMultipart(
            boundary: boundary,
            audioData: wavData,
            metaJSON: metaJSON
        )

        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            do {
                let results = try parseResponse(data: data)
                completion(.success(results))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Private Helpers

    /// Build a multipart/form-data body with "audio" and "meta" fields.
    private static func buildMultipart(boundary: String, audioData: Data, metaJSON: String) -> Data {
        var body = Data()
        let crlf = "\r\n"

        // "audio" field — WAV file bytes
        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.wav\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(audioData)
        body.append(crlf.data(using: .utf8)!)

        // "meta" field — JSON string
        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"meta\"\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(metaJSON.data(using: .utf8)!)
        body.append(crlf.data(using: .utf8)!)

        body.append("--\(boundary)--\(crlf)".data(using: .utf8)!)
        return body
    }

    /// Parse the BirdNET server JSON response.
    /// Expected: { "msg": "success", "results": [["Scientific_Common", 0.78], ...] }
    private static func parseResponse(data: Data) throws -> [BirdNETResult] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidResponse
        }
        guard let msg = json["msg"] as? String, msg == "success" else {
            let errMsg = json["msg"] as? String ?? "unknown"
            throw APIError.serverError(errMsg)
        }
        guard let rawResults = json["results"] as? [[Any]] else {
            return []
        }
        // Each result is [label, confidence] — label format: "Scientific_Common"
        return rawResults.compactMap { pair -> BirdNETResult? in
            guard let label = pair.first as? String,
                  let confidence = pair.last as? Double else { return nil }
            return BirdNETResult(label: label, confidence: confidence)
        }
    }

    /// Encode an AVAudioPCMBuffer to a minimal WAV file in memory.
    /// BirdNET expects mono 48 kHz float32 or 16-bit PCM; we write 16-bit for compatibility.
    private static func encodeWAV(buffer: AVAudioPCMBuffer) -> Data? {
        guard let channelData = buffer.floatChannelData else { return nil }

        let sampleRate   = UInt32(buffer.format.sampleRate)
        let frameCount   = Int(buffer.frameLength)
        let numChannels  = UInt16(1)            // mono
        let bitsPerSample: UInt16 = 16
        let byteRate     = sampleRate * UInt32(numChannels) * UInt32(bitsPerSample) / 8
        let blockAlign   = numChannels * bitsPerSample / 8
        let dataSize     = UInt32(frameCount) * UInt32(blockAlign)
        let chunkSize    = 36 + dataSize

        // Convert Float32 samples → Int16
        let samples = UnsafeBufferPointer(start: channelData[0], count: frameCount)
        let int16Samples = samples.map { sample -> Int16 in
            let clamped = max(-1.0, min(1.0, sample))
            return Int16(clamped * Float(Int16.max))
        }

        var data = Data()
        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.appendLE(chunkSize)
        data.append(contentsOf: "WAVE".utf8)
        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.appendLE(UInt32(16))           // chunk size
        data.appendLE(UInt16(1))            // PCM format
        data.appendLE(numChannels)
        data.appendLE(sampleRate)
        data.appendLE(byteRate)
        data.appendLE(blockAlign)
        data.appendLE(bitsPerSample)
        // data chunk
        data.append(contentsOf: "data".utf8)
        data.appendLE(dataSize)
        int16Samples.forEach { data.appendLE($0) }

        return data
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case encodingFailed
        case noData
        case invalidResponse
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .encodingFailed:    return "Failed to encode audio as WAV"
            case .noData:            return "No data received from server"
            case .invalidResponse:   return "Invalid response format from BirdNET server"
            case .serverError(let m): return "BirdNET server error: \(m)"
            }
        }
    }
}

// MARK: - Data little-endian helpers

private extension Data {
    /// Append a value as little-endian bytes.
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var v = value.littleEndian
        withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
}
