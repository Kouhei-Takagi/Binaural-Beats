//
//  ContentView.swift
//  Binaural-Beats
//
//  Created by 高木耕平 on 2024/08/18.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var audioEngine = AVAudioEngine()
    @State private var playerNode = AVAudioPlayerNode()
    @State private var sampleRate: Double = 44100.0
    @State private var leftFrequency: Double = 100.0 // 左耳の周波数
    @State private var rightFrequency: Double = 110.0 // 右耳の周波数
    
    var body: some View {
        VStack {
            Text("Left Frequency: \(Int(leftFrequency)) Hz")
                .padding()
            
            Slider(value: $leftFrequency, in: 0...200, step: 1)
                .padding()
                .onChange(of: leftFrequency) { _, newValue in
                    playTone(leftFrequency: newValue, rightFrequency: rightFrequency)
                }
            
            Text("Right Frequency: \(Int(rightFrequency)) Hz")
                .padding()
            
            Slider(value: $rightFrequency, in: 0...200, step: 1)
                .padding()
                .onChange(of: rightFrequency) { _, newValue in
                    playTone(leftFrequency: leftFrequency, rightFrequency: newValue)
                }
            
            waveformPicker
            
            Button("Start") {
                startTone()
            }
            .padding()
            
            Button("Stop") {
                stopTone()
            }
            .padding()
        }
        .onAppear {
            setupAudioEngine()
            playTone(leftFrequency: leftFrequency, rightFrequency: rightFrequency)
        }
        .onDisappear {
            stopTone()
        }
    }
    
    func setupAudioEngine() {
        let mainMixer = audioEngine.mainMixerNode
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: mainMixer, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("オーディオエンジンの起動エラー: \(error.localizedDescription)")
        }
    }
    
    enum WaveformType: String, CaseIterable {
        case sine = "Sine"
        case softsine = "Soft sine"
        case triangle = "Triangle"
        case sawtooth = "Sawtooth"
        case square = "Square"
    }

    @State private var selectedWaveform: WaveformType = .softsine

    var waveformPicker: some View {
        Picker("Waveform", selection: $selectedWaveform) {
            ForEach(WaveformType.allCases, id: \.self) {
                Text($0.rawValue)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedWaveform) { oldValue, newValue in
            playTone(leftFrequency: leftFrequency, rightFrequency: rightFrequency)
        }
    }
    
    func playTone(leftFrequency: Double, rightFrequency: Double) {
        playerNode.stop()  // 再生を停止
        
        let minFrequency = max(min(leftFrequency > 0 ? leftFrequency : Double.infinity, rightFrequency > 0 ? rightFrequency : Double.infinity), 1.0)
        let sampleCount = Int(sampleRate / minFrequency)
        var leftWaveform = [Float]()
        var rightWaveform = [Float]()
        
        for i in 0..<sampleCount {
            let leftValue: Float
            let rightValue: Float
            
            if leftFrequency > 0 {
                switch selectedWaveform {
                case .sine:
                    leftValue = Float(sin(2.0 * Double.pi * Double(i) * leftFrequency / sampleRate))
                case .softsine:
                    leftValue = Float(pow(sin(2.0 * Double.pi * Double(i) * leftFrequency / sampleRate), 3))
                case .triangle:
                    leftValue = Float(asin(sin(2.0 * Double.pi * Double(i) * leftFrequency / sampleRate)) * 2.0 / Double.pi)
                case .sawtooth:
                    leftValue = Float(2.0 * (Double(i) * leftFrequency / sampleRate - floor(Double(i) * leftFrequency / sampleRate + 0.5)))
                case .square:
                    leftValue = Float((sin(2.0 * Double.pi * Double(i) * leftFrequency / sampleRate) >= 0) ? 1.0 : -1.0)
                }
            } else {
                leftValue = 0.0
            }
            
            if rightFrequency > 0 {
                switch selectedWaveform {
                case .sine:
                    rightValue = Float(sin(2.0 * Double.pi * Double(i) * rightFrequency / sampleRate))
                case .softsine:
                    rightValue = Float(pow(sin(2.0 * Double.pi * Double(i) * rightFrequency / sampleRate), 3))
                case .triangle:
                    rightValue = Float(asin(sin(2.0 * Double.pi * Double(i) * rightFrequency / sampleRate)) * 2.0 / Double.pi)
                case .sawtooth:
                    rightValue = Float(2.0 * (Double(i) * rightFrequency / sampleRate - floor(Double(i) * rightFrequency / sampleRate + 0.5)))
                case .square:
                    rightValue = Float((sin(2.0 * Double.pi * Double(i) * rightFrequency / sampleRate) >= 0) ? 1.0 : -1.0)
                }
            } else {
                rightValue = 0.0
            }
            
            leftWaveform.append(leftValue)
            rightWaveform.append(rightValue)
        }
        
        let bufferFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
        let buffer = AVAudioPCMBuffer(pcmFormat: bufferFormat!, frameCapacity: AVAudioFrameCount(sampleCount))!
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        
        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]
        
        for i in 0..<sampleCount {
            leftChannel[i] = leftWaveform[i]
            rightChannel[i] = rightWaveform[i]
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()  // 再生を開始
    }
    
    func startTone() {
        playerNode.play()
    }
    
    func stopTone() {
        playerNode.stop()
    }
}

#Preview {
    ContentView()
}
