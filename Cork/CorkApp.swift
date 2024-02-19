//
//  CorkApp.swift
//  Cork
//
//  Created by Mike Freno on 2/15/24.
//

import SwiftUI

@main
struct CorkApp: App {
    var body: some Scene {
        MenuBarExtra("Cork", systemImage: "stopwatch") {
            ContentView()
        }.menuBarExtraStyle(.window)
    }
}
