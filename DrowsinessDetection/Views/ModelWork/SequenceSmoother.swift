//
//  SequenceSmoother.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 19/04/23.
//

import Foundation

struct SequenceSmoother<Element> {
    typealias elementAddFunc = (Element, Element) -> Element
    typealias elementDivideFunc = (Element, Int) -> Element
    
    fileprivate var cache = [Element]()
    fileprivate var maxCacheSize = 5
    fileprivate var currentPos = 0
    fileprivate var emptyElement: Element!
    fileprivate var addFunc: elementAddFunc!
    fileprivate var divideFunc: elementDivideFunc!
    
    
    init(cacheSize: Int = 50, emptyElement:Element, addFunc: @escaping elementAddFunc, divideFunc: @escaping elementDivideFunc) {
        self.maxCacheSize = cacheSize
        self.currentPos = 0
        self.emptyElement = emptyElement
        self.addFunc = addFunc
        self.divideFunc = divideFunc
    }
    
    mutating func resetCache() {
        currentPos = 0
        cache = [Element]()
    }
    
    mutating func smooth(_ value: Element) -> Element {
        if cache.count < maxCacheSize {
            cache.append(value)
        }
        else {
            cache[currentPos] = value
        }
        
        currentPos = (currentPos + 1) % maxCacheSize
        
        //Return Average
        return divideFunc(cache.reduce(emptyElement, addFunc), cache.count)   //cache.reduce(0, +) / cache.count
    }
}

