//
//  DateFormatter+Ext.swift
//  Bird Song
//
//  Shared Date formatting helpers used across the app.
//

import Foundation

extension Date {
    /// Human-readable full date + time string for display (e.g. "Jun 9, 2026 at 10:32 AM")
    var displayString: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    /// Short date only (e.g. "Jun 9, 2026")
    var shortDateString: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    /// Short time only (e.g. "10:32 AM")
    var shortTimeString: String {
        formatted(date: .omitted, time: .shortened)
    }

    /// Safe file name component (e.g. "2026-06-09T10-32-00")
    var exportFilenamePart: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH-mm-ss"
        return f.string(from: self)
    }
}
