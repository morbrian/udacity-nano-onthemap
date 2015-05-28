//
//  Logger.swift
//  OnTheMap
//
//  Created by Brian Moriarty on 4/22/15.
//  Copyright (c) 2015 Brian Moriarty. All rights reserved.
//

import Foundation

// Logger
// Helper class for logging during development.
// Provides file name and line nuber to provide context to the log messages.
public class Logger {
    
    // supported log levels
    // currently only changes the tag in log message.
    // DEBUG = low-level step-through messages to help troubleshoot during development.
    // INFO = messages about significant events or transitions during development.
    // ERROR = unexpected issues or misbehavior to call out during development.
    enum LogLevel: Printable {
        case Debug
        case Info
        case Error
        var description: String {
            switch self {
            case Debug: return "DEBUG"
            case Info: return "INFO"
            case Error: return "ERROR"
            default: return "LOG"
            }
        }
    }
    
    // output the log information in a predefined format
    static private func outputMessage(message: String, file: String, line: Int, function: String, level: LogLevel) {
        println("[\(level)][\(file.lastPathComponent):\(line)][\(function)][\(message)]")
    }
    
    // print debug level messages
    static public func debug(message: String, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
        outputMessage(message, file: file, line: line, function: function, level: LogLevel.Debug)
    }
    
    //print info level messages
    static public func info(message: String, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
        outputMessage(message, file: file, line: line, function: function, level: LogLevel.Info)
    }
    
    // print error level messages
    static public func error(message: String, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
        outputMessage(message, file: file, line: line, function: function, level: LogLevel.Error)
    }
    
}