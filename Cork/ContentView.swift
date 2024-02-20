//
//  ContentView.swift
//  Cork
//
//  Created by Mike Freno on 2/15/24.
//

import SwiftUI
import Combine

class TimerData: ObservableObject {
    @Published var startTime: Date? = nil
    @Published var elapsedTime: TimeInterval = 0
    @Published var heldTime: TimeInterval = 0
    @Published var laps: [TimeInterval] = []
    @Published var previousElapsedTime: TimeInterval = 0
    @Published var countdownTime: TimeInterval = 0
    var timerCancellable: AnyCancellable?
    var countDownCancellable: AnyCancellable?
    
    func start() {
        self.startTime = Date() - self.elapsedTime
        let publisher = Timer.publish(every: 0.1, on: .main, in: .common)
        timerCancellable = publisher.autoconnect().sink { _ in
            if let startTime = self.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    func addLap() {
        if self.laps.count == 0 {
            self.laps.append(self.elapsedTime)
        } else {
            self.laps.append(self.elapsedTime - self.previousElapsedTime)
        }
        self.previousElapsedTime = self.elapsedTime
    }
    
    func removeLap(at index: Int) {
        if index < laps.count {
            let removedLapTime = laps[index]
            laps.remove(at: index)
            if index < laps.count {
                laps[index] += removedLapTime
            } else {
                previousElapsedTime -= removedLapTime
            }
        }
    }
    
    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
        self.heldTime = self.elapsedTime
    }
    
    func reset(){
        timerCancellable?.cancel()
        timerCancellable = nil
        self.heldTime = 0
        self.elapsedTime = 0
        self.laps = []
    }
    
    func startCountdown(from time: TimeInterval) {
        guard countDownCancellable == nil else { return }
        self.countdownTime = time
        let publisher = Timer.publish(every: 0.1, on: .main, in: .common)
        countDownCancellable = publisher.autoconnect().sink { _ in
            if self.countdownTime > 0 {
                self.countdownTime -= 0.1
            } else {
                self.clearCountDown()
            }
        }
    }
    
    func clearCountDown() {
        countDownCancellable?.cancel()
        countDownCancellable = nil
        self.countdownTime = 0
    }
    
    func clearLaps() {
        self.laps = []
    }
}


struct ContentView: View {
    @StateObject var timerData = TimerData()
    @State private var isRunning = false
    @State private var isCountdown = false
    @State private var date: Date = Date()
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle").padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                }
                Spacer()
                Button(action: {
                    self.isCountdown.toggle()
                }, label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .cornerRadius(6)
                        .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                })
            }
            
            if !isCountdown {
                // Timer View
                Text(timeString(time: timerData.elapsedTime))
                    .font(.largeTitle)
                    .padding()
                
                HStack {
                    Button(action: {
                        if self.isRunning {
                            self.timerData.stop()
                        } else {
                            self.timerData.start()
                        }
                        
                        self.isRunning.toggle()
                        
                    }, label: {
                        Text(isRunning ? "Stop" : "Start")
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                    })
                    
                    Button(action: {
                        self.timerData.reset()
                        self.isRunning = false
                        
                    }, label: {
                        Text("Reset")
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                    })
                }
                
                Button(action: {
                    self.timerData.addLap()
                }, label: {
                    Text("Lap")
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                })
                
                if timerData.laps.count > 0 {
                    Button(action: {
                        self.timerData.clearLaps()
                    }, label: {
                        Text("Clear Laps")
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                    })
                    Text("Laps:")
                    ForEach(timerData.laps, id: \.self) { lap in
                        VStack{
                            Divider()
                            HStack{
                                Text(timeString(time: lap))
                                Button(action: {
                                    self.timerData.removeLap(at: self.timerData.laps.firstIndex(of: lap)!)
                                },  label: {
                                    Image(systemName: "xmark.circle")
                                })
                            }
                            
                        }
                    }
                }
            } else {
                VStack {
                    if timerData.countdownTime > 0 {
                        VStack{
                            Text("Time Remaining:")
                                .font(.title)
                            Text((timeString(time: timerData.countdownTime)))
                                .font(.title)
                        }.padding().frame(alignment: .center)
                    }
                    DatePicker("Enter Time:", selection: $date, displayedComponents: [.hourAndMinute])
                    HStack {
                        Button(action: {
                            let time = date.timeIntervalSince(Date())
                            timerData.startCountdown(from: time)
                        }, label: {
                            Text("Start")
                                .padding(.horizontal, 40)
                                .padding(.vertical, 20)
                        })
                        
                        Button(action: {
                            self.timerData.clearCountDown()
                        }, label: {
                            Text("Clear")
                                .padding(.horizontal, 40)
                                .padding(.vertical, 20)
                        })
                    }
                    
                }
                
            }
        }.padding(EdgeInsets(top: 5, leading: 10, bottom: 10, trailing: 10))
    }
    
    func timeString(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        let fraction = Int(time * 10) % 10
        
        if hours > 0 {
            return String(format: "%02i:%02i:%02i.%1i", hours, minutes, seconds, fraction)
        } else if minutes > 0 {
            return String(format: "%02i:%02i.%1i", minutes, seconds, fraction)
        } else if seconds > 10 {
            return String(format: "%02i.%1i", seconds, fraction)
        }else{
            return String(format: "%01i.%1i", seconds, fraction)
        }
    }
}
