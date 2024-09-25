//
//  Queue.swift
//  AudioPlayerProject
//
//  Created by yumi on 9/23/24.
//

import Foundation

class Queue<T> {
    private var elements: [T] = []
    
    // 큐가 비어있는지 확인
    var isEmpty: Bool {
        return elements.isEmpty
    }
    
    // 큐에 데이터 추가
    func enqueue(_ element: T) {
        elements.append(element)
    }
    
    // 큐에서 데이터 추출
    func dequeue() -> T? {
        guard !isEmpty else {
            return nil
        }
        return elements.removeFirst()
    }
    
    // 큐의 가장 앞 데이터 반환
    func peek() -> T? {
        return elements.first
    }
    
    // 큐의 element 개수 반환
    var count: Int {
        return elements.count
    }
    
    var description: String {
        if isEmpty { return "Queue is empty..."}
        return "---- Queue Start ----\n"
        + elements.map({"\($0)"}).joined()
        + "\n---- Queue End ----"
    }
}
