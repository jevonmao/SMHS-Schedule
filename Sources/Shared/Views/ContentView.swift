//
//  ContentView.swift
//  SMHS Schedule
//
//  Created by Jevon Mao on 3/15/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            
            TodayView()
                .tabItem{
                    VStack{
                        Image(systemSymbol: .squareGrid2x2Fill)
                        Text("Today")
                    }
                }
            
            ScheduleView()
                .tabItem{
                    VStack{
                        Image(systemSymbol: .calendar)
                        Text("Schedule")
                    }
                }

            #if DEBUG
            SettingsView()
                .tabItem {
                    VStack {
                        Image(systemSymbol: .gearshapeFill)
                        Text("Settings")
                    }
                }
            #endif
        }
        .onboardingModal()
        .environmentObject(UserSettings())
        .accentColor(Color.primary)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
