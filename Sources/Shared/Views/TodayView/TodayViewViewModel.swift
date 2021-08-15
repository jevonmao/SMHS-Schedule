//
//  TodayViewViewModel.swift
//  SMHSSchedule
//
//  Created by Jevon Mao on 5/7/21.
//

import Combine
import Foundation

class TodayViewViewModel: ObservableObject {
    @Published var showEditModal = false
    @Published var showNetworkError = true
    @Published var selectionMode: PeriodCategory = .firstLunch
    @Published var showPermission = false
}
