//
//  PeriodParseExtensions.swift
//  SMHSSchedule (iOS)
//
//  Created by Jevon Mao on 5/24/21.
//

import Foundation
import Regex

extension ScheduleDay {
    //Regular expression patterns for start time, end time, and period number
    static let startTimePattern: Regex = #"((0?[1-9]|1[0-2]):[0-5][0-9]-)"#.r!
    static let endTimePattern: Regex = #"(-(0?[1-9]|1[0-2]):[0-5][0-9])"#.r!
    static let periodPattern: Regex = #"Period \d"#.r! 
    
    func parseClassPeriods() -> [ClassPeriod] {
        //Will be returned for value of this variable
        var classPeriods: [ClassPeriod] = [ClassPeriod]()
        let textLines: [Substring] = scheduleText.lines
        
        for (line, lineNum) in zip(textLines, 0..<textLines.count) { //Iterate over the line text itself and its index
            guard !line.contains(String(repeating: "-", count: 20)) else {return classPeriods}   //Stop parsing garbage information (sports, after school.etc)
            //Normal period case
            if let startTime: Substring = Self.startTimePattern.findFirst(in: String(line))?.matched.dropLast(), //Optional might be nil because some lines do not contain schedule i
               let endTime: Substring = Self.endTimePattern.findFirst(in: String(line))?.matched.dropFirst(),
               "[a-zA-Z]".r!.matches(String(line))
            {
                classPeriods.append(parseRegularPeriodLine(line, startTime: startTime, endTime: endTime))
            }
            else if let nutritionIndex: Substring.Index = line.range(of: "Nutrition")?.lowerBound, //Handle 1st/2nd nutrition schedule case
                    let period: Match = Self.periodPattern.findFirst(in: String(line)) {
                let block = parseNutritionPeriodLines(textLines,
                                          lineNum: lineNum,
                                          nutritionIndex: nutritionIndex,
                                          period: period)
                classPeriods.append(contentsOf: block) 
            }
        }
        return classPeriods
    }
    
    func parseRegularPeriodLine(_ line: Substring, startTime: Substring, endTime:Substring) -> ClassPeriod {
        guard !line.contains("Office Hours") else {
            return ClassPeriod(nutritionBlock: .officeHour,
                                            startTime: DateFormatter.formatTime12to24(startTime) ?? currentDate,
                                            endTime: DateFormatter.formatTime12to24(endTime) ?? currentDate)
        }
        guard let period: Character = Self.periodPattern.findFirst(in: String(line))?.matched.last else {
            return ClassPeriod(nutritionBlock: .singleLunch,
                                            startTime: DateFormatter.formatTime12to24(startTime) ?? currentDate,
                                            endTime: DateFormatter.formatTime12to24(endTime) ?? currentDate)
        }
        return ClassPeriod(nutritionBlock: .period,
                                        periodNumber: Int(String(period)),
                                        startTime: DateFormatter.formatTime12to24(startTime) ?? currentDate,
                                        endTime: DateFormatter.formatTime12to24(endTime) ?? currentDate)
    }
    
    func parseNutritionPeriodLines(_ textLines: [Substring], lineNum: Int, nutritionIndex: String.Index, period: Match) -> [ClassPeriod]? {
        var classPeriods = [ClassPeriod]()
        //Find next line because current line only has label, next line contains time info
        let nextLine = String(textLines[lineNum+1])
        
        //Regex find start times and end times, convert them to array of string, dropping the dash character
        let startTimes: [String] = Array(Self.startTimePattern.findAll(in: nextLine)).map{String($0.matched.dropLast())}
        let endTimes: [String] = Array(Self.endTimePattern.findAll(in: nextLine)).map{String($0.matched.dropFirst())}
        
        //Total of 4 start/end times for nutrition and period revolving it
        guard let startTimeFirst: String = startTimes.first,
              let endTimeFirst: String = endTimes.first,
              let startTimeLast: String = startTimes.last,
              let endTimeLast: String = endTimes.last else {return nil}
        
        //nutritionIndex is location index of "nutrition" label
        //compare nutritionIndex with location of "period #" label to determine which comes 1st
        if nutritionIndex < textLines[lineNum].range(of: period.matched)!.lowerBound {
            classPeriods.append(ClassPeriod(nutritionBlock: .firstLunch,
                                            startTime: DateFormatter.formatTime12to24(startTimeFirst) ?? currentDate,
                                            endTime: DateFormatter.formatTime12to24(endTimeFirst) ?? currentDate))
                                
            guard period.matched.last != nil, let periodNumber: Int = Int(String(period.matched.last!)) else {return nil}
            classPeriods.append(ClassPeriod(nutritionBlock: .secondLunchPeriod,
                                            periodNumber: periodNumber,
                                            startTime: DateFormatter.formatTime12to24(startTimeLast) ?? currentDate,
                                            endTime: DateFormatter.formatTime12to24(endTimeLast) ?? currentDate))
                               
                                     
        }
        
        //Handles case where period # comes before nutrition
        //Reverse the start/end time order
        else {
            classPeriods.append(ClassPeriod(nutritionBlock: .secondLunch,
                                            startTime: DateFormatter.formatTime12to24(startTimeLast) ?? currentDate,
                                            endTime: DateFormatter.formatTime12to24(endTimeLast) ?? currentDate))
                                
            guard period.matched.last != nil, let periodNumber: Int = Int(String(period.matched.last!)) else {return nil}
            classPeriods.append(ClassPeriod(nutritionBlock: .firstLunchPeriod,
                                            periodNumber: periodNumber,
                                            startTime: DateFormatter.formatTime12to24(startTimeFirst) ?? currentDate,
                                            endTime: DateFormatter.formatTime12to24(endTimeFirst) ?? currentDate))
        }
        return classPeriods
    }
}