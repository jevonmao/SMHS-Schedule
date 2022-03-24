//
//  ScheduleViewModel.swift
//  SMHS Schedule
//
//  Created by Jevon Mao on 3/15/21.
//

import Combine
import SwiftUI
import Foundation
import FirebaseRemoteConfig
import Alamofire
import SwiftyXMLParser

final class SharedScheduleInformation: ObservableObject {
    @Storage(key: "lastReloadTime", defaultValue: nil) private var lastReloadTime: Date?
    @AppStorage("ICSText") private var ICSText: String?
    @Published var todaySchedule: ScheduleDay?
    @Published(key: "scheduleWeeks") var scheduleWeeks = [ScheduleWeek]()
    //@Published(key: "customSchedules") var customSchedules = [ClassPeriod]()
    
    
    private var currentWeekday: Int?
    
    private var urlString: String = "https://www.smhs.org/calendar/calendar_379.ics"
    var dateHelper: ScheduleDateHelper = ScheduleDateHelper()
    private var downloader: (String, @escaping (Data?, Error?) -> ()) -> () = Downloader.load
    var currentDaySchedule: ScheduleDay? {
        if let today = todaySchedule,
           scheduleWeeks.isEmpty {
            return today
        }
        let targetDay = scheduleWeeks.compactMap{$0.getDayByDate(Date())}
        return targetDay.first
    }

    init(placeholderText: String? = nil,
         scheduleDateHelper: ScheduleDateHelper = ScheduleDateHelper(),
         downloader: @escaping (String, @escaping (Data?, Error?) -> ()) -> () = Downloader.load,
         purge: Bool = false,
         urlString: String = "https://www.smhs.org/calendar/calendar_379.ics",
         semaphore: DispatchSemaphore? = nil) {
        
        //Handle preview instance with mock placeholder text
        if placeholderText != nil {
            self.ICSText = placeholderText
            return
        }
        if purge {self.lastReloadTime = nil; self.ICSText = nil; self.scheduleWeeks = []}
        self.dateHelper = scheduleDateHelper
        self.urlString = urlString
        self.downloader = downloader
        print("Called fetch data from initializer...")
        fetchData()

        let shouldPurge = globalRemoteConfig.configValue(forKey: "purge_data_onupdate").boolValue
        // Purge all data when app update applied
        // Allow Remote Config override
        if AppVersionStatus.getVersionStatus() == .updated &&
            shouldPurge {
            reset()
        }
    } 
    
    func reloadData() {
        if let time = lastReloadTime {
            // minimum reload interval is 6 hours
            if abs(Date().timeIntervalSince(time)) > TimeInterval(21600) {
                print("Reload valid, fetching data")
                fetchData()
                lastReloadTime = Date()
            }
            print("Reload invalid")
        }
        else {
            print("Reload 1st time, fetching data")
            lastReloadTime = Date()
            fetchData()
        }
        
    }
    // Two data sources for schedule:
    // 1. AppServ API (Used by SMHS official app)
    // Preferred because it's more stable and stil
    // works even if smhs.org is down, and it's also
    // more performant as it loads in batches and don't
    // require intensive parsing
    //
    // 2. smhs.org ICS calendar feed, used as a
    // redundency to fallback on if above fails
    func fetchData(completion: ((Bool) -> Void)? = nil) {
        // AppServ API
        let endpoint = Endpoint.getSchedule(date: Date())
        AF.request(endpoint.request).response {[weak self] response in
            guard let data = response.data
            else {
                completion?(false)
                return
            }
            let xml = XML.parse(data)

            var scheduleDays = [(String, String)]()
            for day in xml["CALENDAR", "EVENT"] {
                if let scheduleText = day["DESCRIPTION"].text,
                   let date = day["EVENTDATE"].text {
                    scheduleDays.append((date, scheduleText))
                }
            }
            self?.scheduleWeeks = self?.dateHelper.parseScheduleXML(forDays: scheduleDays) ?? []
        }
        //Load ICS calendar data from network
//        downloader(urlString){data, error in
//            guard let data = data else {
//                #if DEBUG
//                completion?(false)
//                //print("Error occurred while fetching iCS: \(error!)")
//                #endif
//                return
//            }
//            //Publish changes on main thread
//            DispatchQueue.main.async {
//                // Decode iCS calendar into raw string
//                let rawText = String(data: data, encoding: .utf8) ?? ""
//                #if DEBUG
//                #else
//                // Only reload if the downloaded data is different
//                guard self.ICSText != rawText else {return}
//                #endif
//                self.ICSText = rawText
//                self.dateHelper.parseTodayScheduleData(withRawText: rawText) {day in
//                    DispatchQueue.main.async {
//                        self.todaySchedule = day
//                    }
//                }
//                self.dateHelper.parseScheduleData(withRawText: rawText){result in
//                    DispatchQueue.main.async {
//                        self.scheduleWeeks = result
//                        self.objectWillChange.send()
//                        completion?(true)
//                    }
//                }
//            }
        //}
    }
    
    func reset() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        ICSText = nil; scheduleWeeks = [];
    }
}



struct Downloader {
    static func load(_ urlString: String, completion: @escaping (Data?, Error?) -> ()) {
        let url = URL(string: urlString)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completion(nil, error!)
                return
            }
            completion(data, nil)
        }
        task.resume()
    }
    
    static func mockLoad(_ text: String, completion: @escaping (Data?, Error?) -> ()) {
        completion(text.data(using: .utf8), nil)
    }
}
