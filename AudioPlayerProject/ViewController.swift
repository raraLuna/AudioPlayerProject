//
//  ViewController.swift
//  AudioPlayerProject
//
//  Created by yumi on 7/30/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var justPlayAudioBtn: UIButton!
    @IBOutlet weak var makeByteArrayBtn: UIButton!
    @IBOutlet weak var audioFileToByteArrayBtn: UIButton!
    @IBOutlet weak var byteArrayToPlayAudioBtn: UIButton!
    @IBOutlet weak var audioNodePlayBtn: UIButton!
    
    private let queue = DispatchQueue(label: "SerialQueue", attributes: .concurrent)
    
    lazy var audioEngine = AVAudioEngine()
    var playerNode = AVAudioPlayerNode()
    var audioByteArrays: [[UInt8]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func clickedPlayAudioButton(_ sender: Any) {
        queue.async {
            self.sampleAudioJustPlay()
        }
    }
    
    @IBAction func clickedFileToByteArrayButton(_ sender: Any) {
        queue.async {
            self.sampleAudioFileToByteWithFormat()
        }
    }
    
    @IBAction func clickedByteArrayPlayAudioButton(_ sender: Any) {
        queue.async {
            self.sampleAudioByteArrayToAudioPlayer()
        }
    }
    
    @IBAction func clickedAudioNodePlayButton(_ sender: Any) {
        queue.async {
            self.playAudioNodePlay()
        }
    }
    
    @IBAction func clickedToMakeByteArray(_ sender: Any) {
        queue.async {
            self.readAudioFileToByteDump()
        }
    }
    
    func sampleAudioJustPlay() {
        //let sampleRate = 48000.0
        //let channels: AVAudioChannelCount = 1
        let bus: AVAudioNodeBus = 0
        
        // init engine and node
        self.audioEngine = AVAudioEngine()
        self.playerNode = AVAudioPlayerNode()
        
        if let audioURL = Bundle.main.url(forResource: "sampleAudio_1ch_48000_Int16", withExtension: "wav") {
            do {
                let file: AVAudioFile = try AVAudioFile(forReading: audioURL)
                print("audio play file: \(file)")
                print("audio file format: \(file.fileFormat)")
                
                self.audioEngine.attach(self.playerNode)
                print("audio engine attached nodes: \(self.audioEngine.attachedNodes)")
                print("AVAudio Player Node format: \(playerNode.outputFormat(forBus: bus))")
//                guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(sampleRate), channels: AVAudioChannelCount(channels), interleaved: false) else {
//                    print("Failed to create AVAudioformat")
//                    return
//                }
//                print("Create format: \(String(describing: format))")
                //self.audioEngine.connect(self.playerNode, to: self.audioEngine.outputNode, format: format)
                
                self.audioEngine.connect(self.playerNode, to: self.audioEngine.outputNode, format: file.processingFormat)
                print("Audio File processing format: \(file.processingFormat)")
                print("AVAudio Player Node format: \(playerNode.outputFormat(forBus: bus))")
                print("AVAudio Player Node format.streamDescription.pointee.mBytesPerFrame: \(playerNode.outputFormat(forBus: bus).streamDescription.pointee.mBytesPerFrame)")
                try self.audioEngine.start()
                
                self.playerNode.scheduleFile(file, at: nil, completionHandler: nil)

                
                self.playAudioNodePlay()
                
            } catch {
                print("AVAudioPlayer Error: \(error.localizedDescription)")
            }
        }
    }

    func sampleAudioFileToByteWithFormat() {
        if let url = Bundle.main.url(forResource: "sampleAudio_1ch_48000_Int16", withExtension: "wav") {
            let sampleRate = 48000.0
            let channels: AVAudioChannelCount = 1
            let bitsPerChannel: UInt32 = 16
            let bufferSize: AVAudioFrameCount = 4096
            
            self.readAudioFileToBytesPCMFormat(fileURL: url, sampleRate: sampleRate, channels: channels, bitsPerChannel: bitsPerChannel, bufferSize: bufferSize)
        }
    }

    func sampleAudioByteArrayToAudioPlayer() {
        //if let url = Bundle.main.url(forResource: "sampleAudio_1ch_48000_Int16", withExtension: "wav") {
            let sampleRate = 48000.0
            let channels: AVAudioChannelCount = 1
            //let bitsPerChannel: UInt32 = 16
            //let bufferSize: AVAudioFrameCount = 1024
            
            let byteArrays = self.audioByteArrays
            
            self.playByteArrayToAudioPCM(byteArrays: byteArrays, sampleRate: sampleRate, channels: channels)
        //}
    }

    //func readAudioFileToBytesAll() ->[UInt8]? {
    func readAudioFileToByteDump() {
        print("start make byte array")
        let bus: AVAudioNodeBus = 0
        guard let fileURL = Bundle.main.url(forResource: "sampleAudio_1ch_48000_Int16", withExtension: "wav") else {
            print("Failed to load audioFile.")
            return
        }
        
        do {
            // Load the audio file
            let audioFile = try AVAudioFile(forReading: fileURL)
            
            // Read the audio data into a buffer
            let format = audioFile.processingFormat
            let frameCount = UInt32(audioFile.length)
            print("frameCount: \(frameCount)")
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("Failed to create AVAudioPCMBuffer")
                return
            }
            
            try audioFile.read(into: buffer)
            
            // Convert the buffer to bytes
            guard let channelData = buffer.floatChannelData else {
                print("Failed to access channel data")
                return
            }
            
            let channelDataPointer = channelData.pointee
            let channelDataSize = Int(buffer.frameLength * format.streamDescription.pointee.mBytesPerFrame)
            var byteArray = [UInt8](repeating: 0, count: channelDataSize)
            
            let data = Data(buffer: UnsafeBufferPointer(start: channelDataPointer, count: channelDataSize / MemoryLayout<Float>.size))
            data.copyBytes(to: &byteArray, count: channelDataSize)
            
            print("byteArray: \(byteArray)")
            print("byteArray.count: \(byteArray.count)") // frameCount * 4
            print("Making byte Array finished")

            // play dump file with PCM Buffer
            self.audioEngine = AVAudioEngine()
            self.playerNode = AVAudioPlayerNode()
            
            self.audioEngine.attach(self.playerNode)
            self.audioEngine.connect(self.playerNode, to: self.audioEngine.outputNode, format: format)
            
            try self.audioEngine.start()
            
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(byteArray.count) / (format.streamDescription.pointee.mBytesPerFrame)) else {
                print("Failed to create AVAudioPCMBuffer")
                return
            }
            
            buffer.frameLength = buffer.frameCapacity
            print("buffer.frameLength = buffer.frameCapacity: \(buffer.frameLength)")
            
            let audioBuffer = buffer.audioBufferList.pointee.mBuffers
            
            guard let dst = audioBuffer.mData?.bindMemory(to: UInt8.self, capacity: byteArray.count) else {
                print("Failed to bind memory to destination buffer")
                return
            }
            byteArray.withUnsafeBufferPointer {
                if let baseAddress = $0.baseAddress {
                    dst.update(from: baseAddress, count: byteArray.count)
                    print("Data successfully copied to buffer.")
                } else {
                    print("Failed to get base address of byte array")
                }
            }
            self.playerNode.scheduleBuffer(buffer, completionHandler: nil)

            self.playAudioNodePlay()
            print("AVAudio Format: \(format)")
            print("Audio play finished.")
        } catch {
            print("Error :\(error.localizedDescription)")
        }
    }

    func readAudioFileToBytesPCMFormat(fileURL: URL, sampleRate: Double, channels: AVAudioChannelCount, bitsPerChannel: UInt32, bufferSize: AVAudioFrameCount) {

        var byteCount = 0
        
        do {
            // Load the audio file
            let audioFile = try AVAudioFile(forReading: fileURL)
            print("Loaded audioFile: \(audioFile)")
            
            // Setting custom audio format
            // AVAudioCommonFormat.pcmFormatInt32 = A format that represent signed 32-bit native-endian integers.
            guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: Double(sampleRate), channels: AVAudioChannelCount(channels), interleaved: false) else {
                print("Failed to create AVAudioformat")
                return
            }
            print("Create format: \(String(describing: format))")
            
            // init Array. save byte buffer.
            var byteBuffers: [[UInt8]] = []
            
            print("audioFile Total Length: \(audioFile.length)")
            // Read audio data to buffer
            // present frame position < total frame length
            while audioFile.framePosition < audioFile.length {
                print("audioFile.framePosition: \(audioFile.framePosition)")
                // Make buffer object with format and size
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else {
                    print("Failed to create AVAudioPCMBuffer")
                    return
                }
                print("Buffer object: \(buffer)")
                
                try audioFile.read(into: buffer, frameCount: bufferSize)
                print("successed read audioFile info buffer as frameCount \(bufferSize)")
                // Get channel data with .int32ChannelData
                // What is Channel Data???
                // Apple Document: The buffer's audio sample as floating point values.
                // * pointer : the variable what reference memory's address values saved data
                guard let channelData = buffer.int16ChannelData else {
                    print("Failed to access channel data")
                    return
                }
                print("ChannelData(memory pointer of audio): \(channelData)")
                
                // Get frame length in present buffer
                var frameLength = Int(buffer.frameLength)
                print("FrameLength in present buffer: \(frameLength)")
                
                // Calculate byte count of frame
                // 1byte == 8bits
                // if bitsPerChanner = 16 (16bits Audio) -> byte = 16 bits / 8 = 2 byte
                let bytePerFrame = Int(bitsPerChannel / 8)
                print("Bytes of frame length: \(bytePerFrame)")
                
                // init UInt8 Array with calculate length and fill all values to 0.
                var byteArray = [UInt8](repeating: 0, count: frameLength * bytePerFrame * Int(channels))
                
                for channel in 0 ..< Int(channels) {
                    // Get channel data
                    let channelDataPointer = channelData[channel]
                    print("Channel data[\(channel)]: \(channelDataPointer)")
                    
                    // Convert channelData to Bufferpointer using UnsafeBufferPointer
                    // What is UnsafeBufferPointer??
                    // Apple Document: A nonowning collection interface to a buffer of elements stored contiguously in memory
                    let channelDataBuffer = UnsafeBufferPointer(start: channelDataPointer, count: frameLength)
                    print("UnsafeBufferPointer data: \(channelDataBuffer)")
                    
                    for frame in 0 ..< frameLength {
                        let sample = channelDataBuffer[frame]
                        //print("channelDataBuffer[\(frame)]: \(sample)") // frame : 0~bufferSize
                        
                        // What is littleEndian??
                        // 메모리에 값을 저장할 때 저장 순서
                        // Big Endian: 상위 바이트부터 저장
                        // Little Endian: 하위 바이드부터 저장
                        /// 예) int 4 byte(0x01020304)를 저장할 때 Big Endian은 0x01부터 저장, Little Endian은 0x04부터 저장
                        /// 통신 할 때 Endian의 형식이 같아야 값을 제대로 전달 할 수 있다.
                        let sampleBytes = withUnsafeBytes(of: sample.littleEndian) { Array($0) }
                            for byteIndex in 0 ..< bytePerFrame {
                                byteArray[frame * bytePerFrame * Int(channels) + channel * bytePerFrame + byteIndex] = sampleBytes[byteIndex]
                                //print("byteArray[frame:\(frame) * bytePerFrame:\(bytePerFrame) * Int(channels): \(Int(channels)) + channel: \(channel) * bytePerFrame: \(bytePerFrame) + byteIndex: \(byteIndex)")
                                //print("sampleBytes[\(byteIndex)]: \(sampleBytes[byteIndex])")
                        }
                    }
                }
                print("ByteArray appended to byteBuffer: \(byteArray)")
                byteBuffers.append(byteArray)
                
                byteCount += byteArray.count
                frameLength += Int(buffer.frameLength)
                
                print("pcm total byteCount: \(byteCount)")
                print("pcm total frameLength: \(frameLength)")
            }
            
            for (index, byteArray) in byteBuffers.enumerated() {
                print("byteArray [\(index)] : \(byteArray.count) bytes")
            }
            
            self.audioByteArrays = byteBuffers
            
        } catch {
            print("Error reading audio file: \(error.localizedDescription)")
            return
        }
    }

    func playByteArrayToAudioPCM(byteArrays:[[UInt8]], sampleRate: Double, channels: AVAudioChannelCount) {
//        var byteArrays : [[UInt8]] = []
//        byteArrays = self.audioByteArrays
        
        let bus: AVAudioNodeBus = 0
        
        var byteCount = 0
        var frameLength = 0
        
        // init engine and node
        self.audioEngine = AVAudioEngine()
        self.playerNode = AVAudioPlayerNode()
        
        // Create AudioEngine and AudioPlayerNode.
        // AVAudioEngine: An object that manages a graph of audio nodes, controls playback, and configures real-time rendering constraints.
        // AVAudioPlayerNode: An object for scheduling the playback of buffers or segments of audio files.
        //let audioEngine = AVAudioEngine()
        //let playerNode = AVAudioPlayerNode()
        
        // connect Engine and Node
        self.audioEngine.attach(self.playerNode)
        print("AVAudio Engine attached AVAudio Player Node")
        print("AVAudio Player Node format: \(self.playerNode.outputFormat(forBus: bus))")
        
        // Creadt AudioFormat
        // PCM : Pulse Code Modulation - 펄즈 부호 변조.
        //      아날로그 신호의 디지털 표헌. 신호등급을 균일한 주기로 표본화 한 다음 디지털 코드로 양자화 처리함.
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: false) else {
            print("Failed to create AVAudioformat")
            return
        }
        print("AVAudio Format: \(format)")
        
        // connect mainMixerNode to playerNode
        self.audioEngine.connect(self.playerNode, to: self.audioEngine.outputNode, format: format)
        //audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        print("Audio Player Node connected to AudioEngine.outputNode with format")
        
        do {
            // Before play the audio, start the engine.
            try self.audioEngine.start()
            print("AVaudio Engine start")
            
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            for byteArray in byteArrays {
                print("ByteArray in ByteArrays: \(byteArray)")
                // Create AVAudioPCMBuffer for each byteArray
                //streamDescription: The audio format properties of a stream of audio data
                //pointee: Accesses the instance referenced by this pointer.
                //mBytesPerFrame: The number of bytes from the start of one frame to the start of the next frame in an audio buffer.
                // frameCapacity: The capacity of the buffer in PCM sample frames.
                print("frameCapacity AVAudioFrameCount(byteArray.count) : \(AVAudioFrameCount(byteArray.count))")
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(byteArray.count) / (format.streamDescription.pointee.mBytesPerFrame)) else {
                    print("Failed to create AVAudioPCMBuffer")
                    return
                }
                
                print("format.streamDescription.pointee.mBytesPerFrame: \(format.streamDescription.pointee.mBytesPerFrame)")
                print("AVAudioPCMBuffer: \(buffer)")
                
                //** setFrameLength condition: frameLength <= frameCapacity
                buffer.frameLength = buffer.frameCapacity
                print("Buffer.frameLength = buffer.frameCapacity : \(buffer.frameLength)")
                
                // mBuffer: A variable-length array of audio buffers.
                let audioBuffer = buffer.audioBufferList.pointee.mBuffers
                print("audioBuffer: \(audioBuffer)")
                // mData: A pointer to a buffer of audio data
                // bindMemory: Bind the memory to the specified type and returns a typed pointer to the bound memory
                guard let dst = audioBuffer.mData?.bindMemory(to: UInt8.self, capacity: byteArray.count) else {
                    print("Failed to bind memory to destination buffer")
                    return
                }
                print("dst: \(dst)")
                print("byteArray.count: \(byteArray.count)")
                
                // write byteArray to baseAddress
                byteArray.withUnsafeBufferPointer {
                    if let baseAddress = $0.baseAddress {
                        dst.update(from: baseAddress, count: byteArray.count)
                        print("Data successfully copied to buffer.")
                    } else {
                        print("Failed to get base address of byte array")
                    }
                    //print("baseAddress: \(baseAddress)")
                    
                    //dst.update(from: baseAddress, count: byteArray.count)
                    //print("dst updated")
                }
                byteCount += byteArray.count
                frameLength += Int(buffer.frameLength)
                
                print("pcm total byteCount: \(byteCount)")
                print("pcm total frameLength: \(frameLength)")
                
                print("AVAudio Format: \(format)")
                print("Player Node output format: \(self.playerNode.outputFormat(forBus: bus))")
                // Schedules the playing samples from an audio buffer at the time and playback options you specify.
                self.playerNode.scheduleBuffer(buffer, completionHandler: nil)
                print("Player Node scheduleBuffer prepared")
                //print("Player Node mainMixer format: \(audioEngine.mainMixerNode.outputFormat(forBus: bus))")
                print("Player Node output format: \(self.playerNode.outputFormat(forBus: bus))")
                
            }
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    func playAudioNodePlay() {
        if self.audioEngine.isRunning {
            self.playerNode.play()
            print("Player Node play audio start")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.playerNode.stop()
                self.playerNode.reset()
                print("Player node stop and reset")
                
                self.audioEngine.stop()
                self.audioEngine.reset()
                print("Audio Engine stop and reset")
            }
        } else {
            print("Audio Engine is not running")
        }
    }
}

