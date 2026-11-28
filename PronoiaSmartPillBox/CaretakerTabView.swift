//
//  CaretakerTabView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//

//
//  CaretakerTabView.swift
//  ArgyleTech
//
import SwiftUI
struct CaretakerTabView: View {
    @StateObject private var firebase = FirebaseManager.shared
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            CaretakerDashboardView()
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            PeopleListView()
                .tabItem {
                    Label("People", systemImage: selectedTab == 1 ? "person.2.fill" : "person.2")
                }
                .tag(1)
            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: selectedTab == 2 ? "bell.fill" : "bell")
                }
                .tag(2)
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: selectedTab == 3 ? "doc.fill" : "doc")
                }
                .tag(3)
            CaretakerProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                }
                .tag(4)
        }
        .tint(.coralDark)
    }
}
#Preview {
    CaretakerTabView()
}
