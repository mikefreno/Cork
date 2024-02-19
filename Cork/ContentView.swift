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
    var timerCancellable: AnyCancellable?

    func start() {
        self.startTime = Date() - self.elapsedTime
        let publisher = Timer.publish(every: 0.1, on: .main, in: .common)
        timerCancellable = publisher.autoconnect().sink { _ in
            if let startTime = self.startTime {
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    func stop() {
        timerCancellable?.cancel()
        self.heldTime = self.elapsedTime
    }
    
    func reset(){
        timerCancellable?.cancel()
        self.heldTime = 0
        self.elapsedTime = 0
    }
}



struct ContentView: View {
    
    @ObservedObject var timerData = TimerData()
    @State private var isRunning = false

    var body: some View {
        VStack {
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
            .padding()
        }
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

#Preview {
    ContentView()
}
