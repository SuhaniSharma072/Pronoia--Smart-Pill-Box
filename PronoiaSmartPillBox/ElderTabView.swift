//
//  ElderTabView.swift
//  PronoiaSmartPillBox
//
//  Created by Suhani Sharmaa on 8/23/26.
//


//
//  ElderTabView.swift
//  ArgyleTech
//
//  Created by Suhani Sharmaa on 4/3/26.
//import SwiftUI
import SwiftUI
struct ElderTabView: View {
    @StateObject private var firebase = FirebaseManager.shared
    @State private var selectedTab = 0
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                ElderHomeView()
                    .tabItem {
                        Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)
                MedicationsView()
                    .tabItem {
                        Label("Meds", systemImage: selectedTab == 1 ? "pills.fill" : "pills")
                    }
                    .tag(1)
                AppointmentsView()
                    .tabItem {
                        Label("Calendar", systemImage: selectedTab == 2 ? "calendar.circle.fill" : "calendar")
                    }
                    .tag(2)
                FamilyView()
                    .tabItem {
                        Label("Family", systemImage: selectedTab == 3 ? "person.2.fill" : "person.2")
                    }
                    .tag(3)
                ProfileMenuView()
                    .tabItem {
                        Label("Profile", systemImage: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                    }
                    .tag(4)
            }
            .tint(.mintDark)
            // Only show SOS on Home tab
            if selectedTab == 0 {
                SOSButtonView()
                    .padding(.bottom, 90)
                    .padding(.trailing, 20)
            }
        }
    }
}
#Preview {
    ElderTabView()
}
// MARK: - SOS Button View
struct SOSButtonView: View {
    @StateObject private var firebase = FirebaseManager.shared
    @State private var showSOSDialog  = false
    var body: some View {
        Button {
            showSOSDialog = true
        } label: {
            Text("SOS")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.red)
                .clipShape(Circle())
                .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 4)
        }
        .confirmationDialog(
            " Help Needed",
            isPresented: $showSOSDialog,
            titleVisibility: .visible
        ) {
            
            Button("Alert Caretaker by App") { sendSOSAlert() }
            Button("Cancel", role: .cancel) { }
        }
    }
    private func callCaretaker() {
        guard let user = firebase.currentUser, !user.caretakerPhone.isEmpty else { return }
        let cleaned = user.caretakerPhone
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
    private func sendSOSAlert() {
        // FIX: removed erroneous $ prefix
        guard let user = firebase.currentUser else { return }
        firebase.sendAlert(
            caretakerEmail: user.caretakerEmail,
            elderID:        user.id,
            elderName:      user.name,
            message:        "🆘 \(user.name) needs emergency help!",
            type:           "sos"
        ) { _ in }
    }
}
