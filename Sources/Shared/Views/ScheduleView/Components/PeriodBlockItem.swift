//
//  PeriodBlockItem.swift
//  SMHSSchedule (iOS)
//
//  Created by Jevon Mao on 5/20/21.
//

import SwiftUI

struct PeriodBlockItem: View {
    var block: ClassPeriod
    var scheduleTitle: String
    var body: some View {
        VStack(spacing: 5) {
            VStack {
                HStack(spacing: 20) {
                    HStack {
                        Text("START:")
                            .fontWeight(.medium)
                            .opacity(0.5)
                        Text(formatDate(block.startTime))
                            .fontWeight(.medium)
                    }
                    HStack {
                        HStack {
                            Text("END:")
                                .fontWeight(.medium)
                                .opacity(0.5)
                            Text(formatDate(block.endTime))
                                .fontWeight(.medium)
                        }
                    }
                    Spacer()
                }
                .font(.footnote)
                Spacer()
                Text(scheduleTitle)
                    .fontWeight(.medium)
                    .textAlign(.leading)
                    .font(.title3)
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .foregroundColor(.platformTertiaryBackground)
            
        }
        .frame(maxWidth: .infinity)
        .background(.primary)
        .roundedCorners(cornerRadius: 15)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}
