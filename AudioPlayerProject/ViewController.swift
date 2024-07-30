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
    @IBOutlet weak var audioFileToByteArrayBtn: UIButton!
    @IBOutlet weak var byteArrayToPlayAudioBtn: UIButton!
    @IBOutlet weak var audioNodePlayBtn: UIButton!
    
    lazy var audioEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    var audioByteArrays: [[UInt8]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func clickedPlayAudioButton(_ sender: Any) {
        self.sampleAudioJustPlay()
    }
    
    @IBAction func clickedFileToByteArrayButton(_ sender: Any) {
        self.sampleAudioFileToByteWithFormat()
    }
    
    @IBAction func clickedByteArrayPlayAudioButton(_ sender: Any) {
        self.sampleAudioByteArrayToAudioPlayer()
    }
    
    @IBAction func clickedAudioNodePlayButton(_ sender: Any) {
        self.playAudioNodePlay()
    }
    
    func sampleAudioJustPlay() {
        if let audioURL = Bundle.main.url(forResource: "gs-16b-1c-44100hz_[cut_2sec]", withExtension: "wav") {
            do {
                let file: AVAudioFile = try AVAudioFile(forReading: audioURL)
                
                self.audioEngine.attach(self.playerNode)
                self.audioEngine.connect(self.playerNode, to: self.audioEngine.mainMixerNode, format: file.processingFormat)
                print("Audio File processing format: \(file.processingFormat)")
                
                try self.audioEngine.start()
                
                self.playerNode.scheduleFile(file, at: nil, completionHandler: nil)
                
                self.playAudioNodePlay()
                
            } catch {
                print("AVAudioPlayer Error: \(error.localizedDescription)")
            }
        }
    }

    func sampleAudioFileToByteWithFormat() {
        if let url = Bundle.main.url(forResource: "gs-16b-1c-44100hz_[cut_2sec]", withExtension: "wav") {
            let sampleRate = 48000.0
            let channels: AVAudioChannelCount = 1
            let bitsPerChannel: UInt32 = 16
            let bufferSize: AVAudioFrameCount = 1024
            
            self.readAudioFileToBytesCustomFormat(fileURL: url, sampleRate: sampleRate, channels: channels, bitsPerChannel: bitsPerChannel, bufferSize: bufferSize)
        }
    }

    func sampleAudioByteArrayToAudioPlayer() {
        if let url = Bundle.main.url(forResource: "gs-16b-1c-44100hz_[cut_2sec]", withExtension: "wav") {
            let sampleRate = 48000.0
            let channels: AVAudioChannelCount = 1
            let bitsPerChannel: UInt32 = 16
            let bufferSize: AVAudioFrameCount = 1024
            
            let byteArrays = self.audioByteArrays
            
            self.playByteArrayToAudio(byteArrays: byteArrays, sampleRate: sampleRate, channels: channels)
        }
    }

    func readAudioFileToBytesAll(fileURL: URL) ->[UInt8]? {
        do {
            // Load the audio file
            let audioFile = try AVAudioFile(forReading: fileURL)
            
            // Read the audio data into a buffer
            let format = audioFile.processingFormat
            let frameCount = UInt32(audioFile.length)
            print("frameCount: \(frameCount)")
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                print("Failed to create AVAudioPCMBuffer")
                return nil
            }
            
            try audioFile.read(into: buffer)
            
            // Convert the buffer to bytes
            guard let channelData = buffer.floatChannelData else {
                print("Failed to access channel data")
                return nil
            }
            
            let channelDataPointer = channelData.pointee
            let channelDataSize = Int(buffer.frameLength * format.streamDescription.pointee.mBytesPerFrame)
            var byteArray = [UInt8](repeating: 0, count: channelDataSize)
            
            let data = Data(buffer: UnsafeBufferPointer(start: channelDataPointer, count: channelDataSize / MemoryLayout<Float>.size))
            data.copyBytes(to: &byteArray, count: channelDataSize)
            
            print("byteArray: \(byteArray)")
            return byteArray
            
        } catch {
            print("Error reading audio file:\(error.localizedDescription)")
            return nil
        }
    }

    func readAudioFileToBytesCustomFormat(fileURL: URL, sampleRate: Double, channels: AVAudioChannelCount, bitsPerChannel: UInt32, bufferSize: AVAudioFrameCount) {
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
                // Make buffer object with format and size
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else {
                    print("Failed to create AVAudioPCMBuffer")
                    return
                }
                print("Buffer object: \(buffer)")
                
                try audioFile.read(into: buffer, frameCount: bufferSize)
                
                // Get channel data with .int32ChannelData
                // What is Channel Data???
                // Apple Document: The buffer's audio sample as floating point values.
                /// The floatChannelData property returns pointers to the buffer's audio samples if the buffer's format is 32-bit float.
                /// It returns nil if it's another format.
                /// The returned pointer is to format. channelCount pointers to float.
                /// Each of these pointers is to frameLength vaild samples, which the class spaces by stride samples.
                /// If the format isn't interleaved, as with the stanard deinterleaved float format, the pointers point to separate chunks of memory, and stride property values is 1.
                /// When the format is in a interleaved state, the pointers refer to the same buffer of interleaved sampled, each offset by 1 frame,
                /// and the stride property values is the number of interleaved channels.
                // * pointer : the variable what reference memory's address values saved data
                guard let channelData = buffer.int16ChannelData else {
                    print("Failed to access channel data")
                    return
                }
                print("ChannelData(memory pointer of audio): \(channelData)")
                
                // Get frame length in present buffer
                let frameLength = Int(buffer.frameLength)
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
                    /// You can use an UnsafeBufferPointer instance in low level operations to eliminate uniqueness checks and, in release mode, bounds checks.
                    /// Bounds checks are always performed in debug mode.
                    /// An UnsafeBufferPointer instance is a view into memory and does not own the memory that it references.
                    /// Copying a values of type UnsafeBufferPointer does not copy the instances stores in the underlying memory.
                    /// However, initializing another collection with an UnsafeBufferPointer instence copies the instences out of the referenced memory and into the new collection.
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

    func playByteArrayToAudio(byteArrays:[[UInt8]], sampleRate: Double, channels: AVAudioChannelCount) {
//        var byteArrays : [[UInt8]] = []
//        byteArrays = self.audioByteArrays
        
        let bus: AVAudioNodeBus = 0
        // Create AudioEngine and AudioPlayerNode.
        // AVAudioEngine: An object that manages a graph of audio nodes, controls playback, and configures real-time rendering constraints.
        // AVAudioPlayerNode: An object for scheduling the playback of buffers or segments of audio files.
        //let audioEngine = AVAudioEngine()
        //let playerNode = AVAudioPlayerNode()
        
        // connect Engine and Node
        audioEngine.attach(playerNode)
        print("AVAudio Engine attached AVAudio Player Node")
        print("AVAudio Player Node format: \(playerNode.outputFormat(forBus: bus))")
        
        // Creadt AudioFormat
        guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: sampleRate, channels: channels, interleaved: false) else {
            print("Failed to create AVAudioformat")
            return
        }
        print("AVAudio Format: \(format)")
        
        // connect mainMixerNode to playerNode
        /// One of the benefits of having a mixer in between your player and output nodes is that a mixer will do sample rate conversions.
        /// So your player can output in 44100Hz, even though the speaker's sample rate is 48000Hz.
        /// Another thing to note is that when connecting your player to your mixer,
        /// the format parameter should be the format that the player node is outputting.
        /// This should be able to be inferred though, by setting format to *nil*
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        //audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        print("Audio Player Node connected to AudioEngine.mainMixerNode with format")
        
        do {
            // Before play the audio, start the engine.
            try audioEngine.start()
            print("AVaudio Engine start")
            
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            
            for byteArray in byteArrays {
                print("ByteArray in ByteArrays: \(byteArray)")
                // Create AVAudioPCMBuffer for each byteArray
                //streamDescription: The audio format properties of a stream of audio data
                //pointee: Accesses the instance referenced by this pointer.
                //mBytesPerFrame: The number of bytes from the start of one frame to the start of the next frame in an audio buffer.
                ///For an audio buffer containing interleaved data for n channels, with each sample of type AudioSampleType, calculate the value for this field as follows:
                ///mBytesPerFrame = n * sizeof  (AudioSampleType);      *
                ///For an audio buffer containing noninterleaved (monophonic) data, also using AudioSampleType samples, calculate the value for this field as follows:
                ///mBytesPerFrame = sizeof (AudioSampleType);
                ///Set this field to 0 for compressed formats.
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(byteArray.count) / (format.streamDescription.pointee.mBytesPerFrame)) else {
                    print("Failed to create AVAudioPCMBuffer")
                    return
                }
                print("AVAudioPCMBuffer: \(buffer)")
                
                buffer.frameLength = buffer.frameCapacity
                print("Buffer.frameLength = buffer.frameCapacity : \(buffer.frameLength)")
                
                // mBuffer: A variable-length array of audio buffers.
                let audioBuffer = buffer.audioBufferList.pointee.mBuffers
                print("audioBuffer: \(audioBuffer)")
                // mData: A pointer to a buffer of audio data
                // bindMemory: Bind the memory to the specified type and returns a typed pointer to the bound memory
                ///to: type   : The type T to bind the memory to.
                ///capacity: count    : The amount of memory to bind to type T, counted as instances of T.
                ///Return Value : A typed pointer to the newly bound memory.
                ///          The memory in this region is bound to T, but has not been modified in any other way.
                ///          The number of bytes in this region is count * MemoryLayout<T>.stride.        *
                ///Discussion :
                ///  Use the bindMemory(to:capacity:) method to bind the memory referenced by this pointer to the Type T.
                ///  The memory must be uninitialized or initialized to a type that is layout compatible with T.
                ///  If the memory is uninitialized, it is uninitialized after being bounds to T.
                ///  In this example, 100bytes of raw memory are allocated for the pointer bytesPointer, and then the first four bytes are bound to the UInt 8 type.
                ///  let count = 4
                ///  let bytesPointer = UnsafeMutableRawPointer.allocate(
                ///        byteCount: 100,
                ///        alignment: MemoryLayout<Int8>.alignment)
                ///  let int8Pointer = bytesPointer.bindMemory(to: Int8.self, capacity: count)
                ///  After calling bindMemory(to:capacity:), the first four bytes of the memory referenced by bytesPointer are bound to the Int8 type, though they remain uninitialized.
                ///  The remainder of the allocated region is unbound raw memory.
                ///  All 100 bytes of memory must eventually be deallocated.
                guard let dst = audioBuffer.mData?.bindMemory(to: UInt8.self, capacity: byteArray.count) else {
                    print("Failed to bind memory to destination buffer")
                    return
                }
                print("dst: \(dst)")
                
                // write byteArray to baseAddress
                byteArray.withUnsafeBufferPointer {
                    guard let baseAddress = $0.baseAddress else {
                        print("Failed to get base address of byte array")
                        return
                    }
                    print("baseAddress: \(baseAddress)")
                    
                    dst.update(from: baseAddress, count: byteArray.count)
                    print("dst updated from baseAddress by count: \(byteArray.count)")
                }
                
                // Schedules the playing samples from an audio buffer at the time and playback options you specify.
                playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
                print("Player Node scheduleBuffer prepared")
                
            }
//            playerNode.play()
//            print("Player Node play audio start")
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                playerNode.stop()
//                self.audioEngine.stop()
//                print("Player node and engine stop")
//            }
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    func playAudioNodePlay() {
        if self.audioEngine.isRunning {
            playerNode.play()
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

