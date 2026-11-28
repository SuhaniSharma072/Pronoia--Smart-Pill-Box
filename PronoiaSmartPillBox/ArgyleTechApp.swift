//
//  ArgyleTechApp.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

//
//  ArgyleTechApp.swift
//  ArgyleTech
//
import SwiftUI
import Firebase
@main
struct ArgyleTech: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
