//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  ObjectMatcherTests.swift
//  CoatySwift

import XCTest
import CoatySwift

class ObjectMatcherTests: XCTestCase {
    
    func testMatchesFilterSingleCondition() throws {
        let obj = CoatyObject(coreType: .Log,
                              objectType: Log.objectType,
                              objectId: .init(),
                              name: "Hello")
        
        let filter = ObjectFilter(condition: ObjectFilterCondition(property: ObjectFilterProperty("name"),
                                                                   expression: ObjectFilterExpression(filterOperator: .Equals,
                                                                                                      op1: "Hello")))
        
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: obj, filter: filter))
    }
    
    func testMatchesFilterAndConditions() throws {
        let dotTest2: [String: Any] = [
            "hello": "hello"
        ]
        
        let dotTest1: [String: Any] = [
            ".": dotTest2
        ]
        
        let nestedDictionary: [String: Any] = [
            "lastProperty": 42,
            ".": dotTest1
        ]
        
        let nestedObject = Log(logLevel: .info,
                               logMessage: "ABCD",
                               logDate: "22.01.2001",
                               name: "ABBBBC",
                               objectType: Log.objectType,
                               objectId: .init(),
                               logLabels: nestedDictionary)
        
        let simpleLog = Log(logLevel: .info, logMessage: "Hello", logDate: "42")
        let simpleLog2 = Log(logLevel: .info, logMessage: "Hello", logDate: "43")
        let complexLog = Log(logLevel: .info, logMessage: "Hello", logDate: "42", name: "LogObject", objectType: Log.objectType, objectId: simpleLog.objectId)
        
        // Create hierarchy of objects used for testing.
        let logLabels: [String: Any] = [
            "boolean": true,
            "number": 42,
            "string": "Abc",
            "array": [42, [43, 44], [[45, 46]]],
            "array1": [1, 2, 3],
            "array2": [1, [2, 3, 4], 3],
            "filterLikeString": "hello abc\\d_",
            "filterLikeString1": ".*+?^${}()|[]",
            "filterLikeString2": "/",
            ".": 42,
            "nestedObject": nestedObject,
            "complexLog": complexLog
        ]
        
        let thirdObject = Log(logLevel: .info,
                              logMessage: "ABC",
                              logDate: "22.01.2001",
                              name: "AbCC",
                              objectType: Log.objectType,
                              objectId: .init(),
                              logTags: ["Tag1", "Tag2"],
                              logLabels: logLabels,
                              logHost: nil)
        
        let secondObject = Snapshot(creationTimestamp: 1.0,
                                    creatorId: .init(),
                                    object: thirdObject)
        
        let firstObject = Snapshot(creationTimestamp: 2.0,
                                   creatorId: .init(),
                                   object: secondObject)
        
        // Initialize the filter object
        // NOTE: It is impossible to create an empty filter with provided intializers, that's why condition and conditions have to be nilled later
        var filter = ObjectFilter(condition: ObjectFilterCondition(property: ObjectFilterProperty("_"),
                                                                   expression: ObjectFilterExpression(filterOperator: ObjectFilterOperator(rawValue: 0)!)))
        filter.condition = nil
        filter.conditions = nil
        
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: nil, filter: nil))
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: nil, filter: filter))
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: nil))
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
        
        // Create new filter with 'and' conditions
        let conditions: [ObjectFilterCondition] = [
            // MARK: - Test: .Exists and .NotExists; .Equals and .NotEquals for primitives.
            ObjectFilterCondition(property: ObjectFilterProperty("foo"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("foo.bar"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logHost"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: true)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: false)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: "abc")),

            // MARK: - Test: Object nested in Dictionary nested in Object
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.nestedObject.logLabels.lastProperty"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.nestedObject.logLabels.foo"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            
            // MARK: - Test: .Equals and .NotEquals for arrays.
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: [42, [43, 44], [[45, 46]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: [42, [43, 44], [[45, 47]]])),

            // MARK: - Test: .Equals and .NotEquals for objects.
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: AnyCodable(Log(logLevel: .info,
                                                                                                                  logMessage: "ABC",
                                                                                                                  logDate: "22.01.2001",
                                                                                                                  name: "AbCC",
                                                                                                                  objectType: Log.objectType,
                                                                                                                  objectId: thirdObject.objectId,
                                                                                                                  logTags: ["Tag1", "Tag2"],
                                                                                                                  logLabels: logLabels,
                                                                                                                  logHost: nil)))),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: AnyCodable(Log(logLevel: .info,
                                                                                                                     logMessage: "...",
                                                                                                                     logDate: "...",
                                                                                                                     name: "...",
                                                                                                                     objectType: Log.objectType,
                                                                                                                     objectId: .init(),
                                                                                                                     logTags: ["Tag1", "Tag2"],
                                                                                                                     logLabels: logLabels,
                                                                                                                     logHost: nil)))),
            
            // MARK: - TEST: Properties with dot names and properties specified as array
            ObjectFilterCondition(property: ObjectFilterProperty(["object", "object", "logLabels", "nestedObject", "logLabels", ".", ".", "hello"]),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: "hello")),
            
            // MARK: - Test: .LessThan, .LessThanOrEqual, .GreaterThan, .GreaterThanOrEqual
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThan, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThan, op1: "Abce")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThanOrEqual, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThanOrEqual, op1: "ABc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThan, op1: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThan, op1: "abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThanOrEqual, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThanOrEqual, op1: "Abc")),

            // MARK: - Test: .Between
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 42, op2: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 41, op2: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 43, op2: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abc", op2: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abb", op2: "Abd")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abd", op2: "Abb")),

            // MARK: - Test: .NotBetween
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 43, op2: 47)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 47, op2: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 41, op2: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abd", op2: "Abf")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abf", op2: "Abd")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abb", op2: "Abb")),

            // MARK: - Test: .Like
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "Ab_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_b_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "___")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%__")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%___")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "__%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "__%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "___%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%bc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%c")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%c")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%a_c\\\\d\\_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString1"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: ".*+?^${}()|[]")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString2"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "\\/")),
            
            // MARK: - Test: .Contains
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [42])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [42, [43], [[46]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, 1])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, 1, 3, 1])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array2"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, [3, 2]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.complexLog"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: AnyCodable(simpleLog))),
            
            // MARK: - Test: .NotContains
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [41, [45], [[43]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [3, 1, 5])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array2"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [3, [3, 1]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.complexLog"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: AnyCodable(simpleLog2))),
             
            // MARK: - Test: .In
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, 42, "42"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, 42, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, true, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [
                                    Log(logLevel: .info,
                                        logMessage: "ABC",
                                        logDate: "22.01.2001",
                                        name: "AbCC",
                                        objectType:
                                        Log.objectType,
                                        objectId: thirdObject.objectId,
                                        logTags: ["Tag1", "Tag2"],
                                        logLabels: logLabels,
                                        logHost: nil),
                                    Log(logLevel: .info,
                                        logMessage: "Dummy",
                                        logDate: "2.2.2020")
                                  ])),

            // MARK: - Test: .NotIn
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, 41, "42"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, 42, "abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, false, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [
                                    Log(logLevel: .info,
                                        logMessage: "ABC",
                                        logDate: "22.01.2001",
                                        // Only name property is not the same as in object.object
                                        name: "AbCCC",
                                        objectType:
                                        Log.objectType,
                                        objectId: thirdObject.objectId,
                                        logTags: ["Tag1", "Tag2"],
                                        logLabels: logLabels,
                                        logHost: nil),
                                    Log(logLevel: .info,
                                        logMessage: "Dummy",
                                        logDate: "2.2.2020")
                                  ])),
            
        ]
        
        filter = ObjectFilter(conditions: ObjectFilterConditions(and: conditions))
        
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
    }
    
    func testMatchesFilterOrConditions() throws {
        let dotTest2: [String: Any] = [
            "hello": "hello"
        ]
        
        let dotTest1: [String: Any] = [
            ".": dotTest2
        ]
        
        let nestedDictionary: [String: Any] = [
            "lastProperty": 42,
            ".": dotTest1
        ]
        
        let nestedObject = Log(logLevel: .info,
                               logMessage: "ABCD",
                               logDate: "22.01.2001",
                               name: "ABBBBC",
                               objectType: Log.objectType,
                               objectId: .init(),
                               logLabels: nestedDictionary)
        
        let simpleLog = Log(logLevel: .info, logMessage: "Hello", logDate: "42")
        let simpleLog2 = Log(logLevel: .info, logMessage: "Hello", logDate: "43")
        let complexLog = Log(logLevel: .info, logMessage: "Hello", logDate: "42", name: "LogObject", objectType: Log.objectType, objectId: simpleLog.objectId)
        
        // Create hierarchy of objects used for testing.
        let logLabels: [String: Any] = [
            "boolean": true,
            "number": 42,
            "string": "Abc",
            "array": [42, [43, 44], [[45, 46]]],
            "array1": [1, 2, 3],
            "array2": [1, [2, 3, 4], 3],
            "filterLikeString": "hello abc\\d_",
            "filterLikeString1": ".*+?^${}()|[]",
            "filterLikeString2": "/",
            ".": 42,
            "nestedObject": nestedObject,
            "complexLog": complexLog
        ]
        
        let thirdObject = Log(logLevel: .info,
                              logMessage: "ABC",
                              logDate: "22.01.2001",
                              name: "AbCC",
                              objectType: Log.objectType,
                              objectId: .init(),
                              logTags: ["Tag1", "Tag2"],
                              logLabels: logLabels,
                              logHost: nil)
        
        let secondObject = Snapshot(creationTimestamp: 1.0,
                                    creatorId: .init(),
                                    object: thirdObject)
        
        let firstObject = Snapshot(creationTimestamp: 2.0,
                                   creatorId: .init(),
                                   object: secondObject)
        
        // Initialize the filter object
        // NOTE: It is impossible to create an empty filter with provided intializers, that's why condition and conditions have to be nilled later
        var filter = ObjectFilter(condition: ObjectFilterCondition(property: ObjectFilterProperty("_"),
                                                                   expression: ObjectFilterExpression(filterOperator: ObjectFilterOperator(rawValue: 0)!)))
        filter.condition = nil
        filter.conditions = nil
        
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: nil, filter: nil))
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: nil, filter: filter))
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: nil))
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
        
        // Create new filter with 'and' conditions
        let conditions: [ObjectFilterCondition] = [
            // MARK: - Test: .Exists and .NotExists; .Equals and .NotEquals for primitives.
            ObjectFilterCondition(property: ObjectFilterProperty("foo"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("foo.bar"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logHost"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: true)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: false)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: "abc")),

            // MARK: - Test: Object nested in Dictionary nested in Object
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.nestedObject.logLabels.lastProperty"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.nestedObject.logLabels.foo"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            
            // MARK: - Test: .Equals and .NotEquals for arrays.
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: [42, [43, 44], [[45, 46]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: [42, [43, 44], [[45, 47]]])),

            // MARK: - Test: .Equals and .NotEquals for objects.
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: AnyCodable(Log(logLevel: .info,
                                                                                                                  logMessage: "ABC",
                                                                                                                  logDate: "22.01.2001",
                                                                                                                  name: "AbCC",
                                                                                                                  objectType: Log.objectType,
                                                                                                                  objectId: thirdObject.objectId,
                                                                                                                  logTags: ["Tag1", "Tag2"],
                                                                                                                  logLabels: logLabels,
                                                                                                                  logHost: nil)))),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: AnyCodable(Log(logLevel: .info,
                                                                                                                     logMessage: "...",
                                                                                                                     logDate: "...",
                                                                                                                     name: "...",
                                                                                                                     objectType: Log.objectType,
                                                                                                                     objectId: .init(),
                                                                                                                     logTags: ["Tag1", "Tag2"],
                                                                                                                     logLabels: logLabels,
                                                                                                                     logHost: nil)))),
            
            // MARK: - TEST: Properties with dot names and properties specified as array
            ObjectFilterCondition(property: ObjectFilterProperty(["object", "object", "logLabels", "nestedObject", "logLabels", ".", ".", "hello"]),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: "hello")),
            
            // MARK: - Test: .LessThan, .LessThanOrEqual, .GreaterThan, .GreaterThanOrEqual
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThan, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThan, op1: "Abce")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThanOrEqual, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThanOrEqual, op1: "ABc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThan, op1: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThan, op1: "abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThanOrEqual, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThanOrEqual, op1: "Abc")),

            // MARK: - Test: .Between
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 42, op2: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 41, op2: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 43, op2: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abc", op2: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abb", op2: "Abd")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abd", op2: "Abb")),

            // MARK: - Test: .NotBetween
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 43, op2: 47)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 47, op2: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 41, op2: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abd", op2: "Abf")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abf", op2: "Abd")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abb", op2: "Abb")),

            // MARK: - Test: .Like
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "Ab_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_b_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "___")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%__")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%___")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "__%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "__%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "___%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%bc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%c")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%c")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%a_c\\\\d\\_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString1"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: ".*+?^${}()|[]")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString2"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "\\/")),
            
            // MARK: - Test: .Contains
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [42])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [42, [43], [[46]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, 1])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, 1, 3, 1])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array2"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, [3, 2]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.complexLog"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: AnyCodable(simpleLog))),
            
            // MARK: - Test: .NotContains
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [41, [45], [[43]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [3, 1, 5])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array2"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [3, [3, 1]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.complexLog"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: AnyCodable(simpleLog2))),
             
            // MARK: - Test: .In
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, 42, "42"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, 42, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, true, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [
                                    Log(logLevel: .info,
                                        logMessage: "ABC",
                                        logDate: "22.01.2001",
                                        name: "AbCC",
                                        objectType:
                                        Log.objectType,
                                        objectId: thirdObject.objectId,
                                        logTags: ["Tag1", "Tag2"],
                                        logLabels: logLabels,
                                        logHost: nil),
                                    Log(logLevel: .info,
                                        logMessage: "Dummy",
                                        logDate: "2.2.2020")
                                  ])),

            // MARK: - Test: .NotIn
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, 41, "42"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, 42, "abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, false, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [
                                    Log(logLevel: .info,
                                        logMessage: "ABC",
                                        logDate: "22.01.2001",
                                        // Only name property is not the same as in object.object
                                        name: "AbCCC",
                                        objectType:
                                        Log.objectType,
                                        objectId: thirdObject.objectId,
                                        logTags: ["Tag1", "Tag2"],
                                        logLabels: logLabels,
                                        logHost: nil),
                                    Log(logLevel: .info,
                                        logMessage: "Dummy",
                                        logDate: "2.2.2020")
                                  ])),
            
        ]
        
        filter = ObjectFilter(conditions: ObjectFilterConditions(or: conditions))
        
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
    }
    
    func testBothSingleConditionAndAndCondtions() throws {
        // For single condition
        let singleCondition = ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                                    expression: ObjectFilterExpression(filterOperator: .Equals, op1: "Abc"))
        
        // For And conditions
        let dotTest2: [String: Any] = [
            "hello": "hello"
        ]
        
        let dotTest1: [String: Any] = [
            ".": dotTest2
        ]
        
        let nestedDictionary: [String: Any] = [
            "lastProperty": 42,
            ".": dotTest1
        ]
        
        let nestedObject = Log(logLevel: .info,
                               logMessage: "ABCD",
                               logDate: "22.01.2001",
                               name: "ABBBBC",
                               objectType: Log.objectType,
                               objectId: .init(),
                               logLabels: nestedDictionary)
        
        let simpleLog = Log(logLevel: .info, logMessage: "Hello", logDate: "42")
        let simpleLog2 = Log(logLevel: .info, logMessage: "Hello", logDate: "43")
        let complexLog = Log(logLevel: .info, logMessage: "Hello", logDate: "42", name: "LogObject", objectType: Log.objectType, objectId: simpleLog.objectId)
        
        // Create hierarchy of objects used for testing.
        let logLabels: [String: Any] = [
            "boolean": true,
            "number": 42,
            "string": "Abc",
            "array": [42, [43, 44], [[45, 46]]],
            "array1": [1, 2, 3],
            "array2": [1, [2, 3, 4], 3],
            "filterLikeString": "hello abc\\d_",
            "filterLikeString1": ".*+?^${}()|[]",
            "filterLikeString2": "/",
            ".": 42,
            "nestedObject": nestedObject,
            "complexLog": complexLog
        ]
        
        let thirdObject = Log(logLevel: .info,
                              logMessage: "ABC",
                              logDate: "22.01.2001",
                              name: "AbCC",
                              objectType: Log.objectType,
                              objectId: .init(),
                              logTags: ["Tag1", "Tag2"],
                              logLabels: logLabels,
                              logHost: nil)
        
        let secondObject = Snapshot(creationTimestamp: 1.0,
                                    creatorId: .init(),
                                    object: thirdObject)
        
        let firstObject = Snapshot(creationTimestamp: 2.0,
                                   creatorId: .init(),
                                   object: secondObject)
        
        // Initialize the filter object
        // NOTE: It is impossible to create an empty filter with provided intializers, that's why condition and conditions have to be nilled later
        var filter = ObjectFilter(condition: ObjectFilterCondition(property: ObjectFilterProperty("_"),
                                                                   expression: ObjectFilterExpression(filterOperator: ObjectFilterOperator(rawValue: 0)!)))
        filter.condition = nil
        filter.conditions = nil
        
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: nil, filter: nil))
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: nil, filter: filter))
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: nil))
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
        
        // Create new filter with 'and' conditions
        let conditions: [ObjectFilterCondition] = [
            // MARK: - Test: .Exists and .NotExists; .Equals and .NotEquals for primitives.
            ObjectFilterCondition(property: ObjectFilterProperty("foo"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("foo.bar"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logHost"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: true)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: false)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: "abc")),

            // MARK: - Test: Object nested in Dictionary nested in Object
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.nestedObject.logLabels.lastProperty"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.nestedObject.logLabels.foo"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            
            // MARK: - Test: .Equals and .NotEquals for arrays.
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: [42, [43, 44], [[45, 46]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: [42, [43, 44], [[45, 47]]])),

            // MARK: - Test: .Equals and .NotEquals for objects.
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: AnyCodable(Log(logLevel: .info,
                                                                                                                  logMessage: "ABC",
                                                                                                                  logDate: "22.01.2001",
                                                                                                                  name: "AbCC",
                                                                                                                  objectType: Log.objectType,
                                                                                                                  objectId: thirdObject.objectId,
                                                                                                                  logTags: ["Tag1", "Tag2"],
                                                                                                                  logLabels: logLabels,
                                                                                                                  logHost: nil)))),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: AnyCodable(Log(logLevel: .info,
                                                                                                                     logMessage: "...",
                                                                                                                     logDate: "...",
                                                                                                                     name: "...",
                                                                                                                     objectType: Log.objectType,
                                                                                                                     objectId: .init(),
                                                                                                                     logTags: ["Tag1", "Tag2"],
                                                                                                                     logLabels: logLabels,
                                                                                                                     logHost: nil)))),
            
            // MARK: - TEST: Properties with dot names and properties specified as array
            ObjectFilterCondition(property: ObjectFilterProperty(["object", "object", "logLabels", "nestedObject", "logLabels", ".", ".", "hello"]),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: "hello")),
            
            // MARK: - Test: .LessThan, .LessThanOrEqual, .GreaterThan, .GreaterThanOrEqual
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThan, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThan, op1: "Abce")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThanOrEqual, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThanOrEqual, op1: "ABc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThan, op1: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThan, op1: "abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThanOrEqual, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThanOrEqual, op1: "Abc")),

            // MARK: - Test: .Between
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 42, op2: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 41, op2: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 43, op2: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abc", op2: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abb", op2: "Abd")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abd", op2: "Abb")),

            // MARK: - Test: .NotBetween
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 43, op2: 47)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 47, op2: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 41, op2: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abd", op2: "Abf")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abf", op2: "Abd")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abb", op2: "Abb")),

            // MARK: - Test: .Like
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "Ab_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_b_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "___")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%__")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%___")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "__%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "__%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "___%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%bc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%c")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%c")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%a_c\\\\d\\_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString1"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: ".*+?^${}()|[]")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString2"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "\\/")),
            
            // MARK: - Test: .Contains
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [42])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [42, [43], [[46]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, 1])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, 1, 3, 1])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array2"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, [3, 2]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.complexLog"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: AnyCodable(simpleLog))),
            
            // MARK: - Test: .NotContains
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [41, [45], [[43]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [3, 1, 5])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array2"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [3, [3, 1]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.complexLog"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: AnyCodable(simpleLog2))),
             
            // MARK: - Test: .In
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, 42, "42"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, 42, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, true, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [
                                    Log(logLevel: .info,
                                        logMessage: "ABC",
                                        logDate: "22.01.2001",
                                        name: "AbCC",
                                        objectType:
                                        Log.objectType,
                                        objectId: thirdObject.objectId,
                                        logTags: ["Tag1", "Tag2"],
                                        logLabels: logLabels,
                                        logHost: nil),
                                    Log(logLevel: .info,
                                        logMessage: "Dummy",
                                        logDate: "2.2.2020")
                                  ])),

            // MARK: - Test: .NotIn
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, 41, "42"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, 42, "abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, false, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [
                                    Log(logLevel: .info,
                                        logMessage: "ABC",
                                        logDate: "22.01.2001",
                                        // Only name property is not the same as in object.object
                                        name: "AbCCC",
                                        objectType:
                                        Log.objectType,
                                        objectId: thirdObject.objectId,
                                        logTags: ["Tag1", "Tag2"],
                                        logLabels: logLabels,
                                        logHost: nil),
                                    Log(logLevel: .info,
                                        logMessage: "Dummy",
                                        logDate: "2.2.2020")
                                  ])),
            
        ]
        
        filter = ObjectFilter(conditions: ObjectFilterConditions(and: conditions))
        
        // Edge case
        filter.condition = singleCondition
        
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
    }
    
    func testBothSingleConditionAndOrCondtions() throws {
        // For single condition
        let singleCondition = ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                                    expression: ObjectFilterExpression(filterOperator: .Equals, op1: "Abc"))
        
        // For And conditions
        let dotTest2: [String: Any] = [
            "hello": "hello"
        ]
        
        let dotTest1: [String: Any] = [
            ".": dotTest2
        ]
        
        let nestedDictionary: [String: Any] = [
            "lastProperty": 42,
            ".": dotTest1
        ]
        
        let nestedObject = Log(logLevel: .info,
                               logMessage: "ABCD",
                               logDate: "22.01.2001",
                               name: "ABBBBC",
                               objectType: Log.objectType,
                               objectId: .init(),
                               logLabels: nestedDictionary)
        
        let simpleLog = Log(logLevel: .info, logMessage: "Hello", logDate: "42")
        let simpleLog2 = Log(logLevel: .info, logMessage: "Hello", logDate: "43")
        let complexLog = Log(logLevel: .info, logMessage: "Hello", logDate: "42", name: "LogObject", objectType: Log.objectType, objectId: simpleLog.objectId)
        
        // Create hierarchy of objects used for testing.
        let logLabels: [String: Any] = [
            "boolean": true,
            "number": 42,
            "string": "Abc",
            "array": [42, [43, 44], [[45, 46]]],
            "array1": [1, 2, 3],
            "array2": [1, [2, 3, 4], 3],
            "filterLikeString": "hello abc\\d_",
            "filterLikeString1": ".*+?^${}()|[]",
            "filterLikeString2": "/",
            ".": 42,
            "nestedObject": nestedObject,
            "complexLog": complexLog
        ]
        
        let thirdObject = Log(logLevel: .info,
                              logMessage: "ABC",
                              logDate: "22.01.2001",
                              name: "AbCC",
                              objectType: Log.objectType,
                              objectId: .init(),
                              logTags: ["Tag1", "Tag2"],
                              logLabels: logLabels,
                              logHost: nil)
        
        let secondObject = Snapshot(creationTimestamp: 1.0,
                                    creatorId: .init(),
                                    object: thirdObject)
        
        let firstObject = Snapshot(creationTimestamp: 2.0,
                                   creatorId: .init(),
                                   object: secondObject)
        
        // Initialize the filter object
        // NOTE: It is impossible to create an empty filter with provided intializers, that's why condition and conditions have to be nilled later
        var filter = ObjectFilter(condition: ObjectFilterCondition(property: ObjectFilterProperty("_"),
                                                                   expression: ObjectFilterExpression(filterOperator: ObjectFilterOperator(rawValue: 0)!)))
        filter.condition = nil
        filter.conditions = nil
        
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: nil, filter: nil))
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: nil, filter: filter))
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: nil))
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
        
        // Create new filter with 'and' conditions
        let conditions: [ObjectFilterCondition] = [
            // MARK: - Test: .Exists and .NotExists; .Equals and .NotEquals for primitives.
            ObjectFilterCondition(property: ObjectFilterProperty("foo"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("foo.bar"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logHost"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: true)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: false)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: "abc")),

            // MARK: - Test: Object nested in Dictionary nested in Object
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.nestedObject.logLabels.lastProperty"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.nestedObject.logLabels.foo"),
                                  expression: ObjectFilterExpression(filterOperator: .NotExists)),
            
            // MARK: - Test: .Equals and .NotEquals for arrays.
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: [42, [43, 44], [[45, 46]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: [42, [43, 44], [[45, 47]]])),

            // MARK: - Test: .Equals and .NotEquals for objects.
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: AnyCodable(Log(logLevel: .info,
                                                                                                                  logMessage: "ABC",
                                                                                                                  logDate: "22.01.2001",
                                                                                                                  name: "AbCC",
                                                                                                                  objectType: Log.objectType,
                                                                                                                  objectId: thirdObject.objectId,
                                                                                                                  logTags: ["Tag1", "Tag2"],
                                                                                                                  logLabels: logLabels,
                                                                                                                  logHost: nil)))),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .NotEquals, op1: AnyCodable(Log(logLevel: .info,
                                                                                                                     logMessage: "...",
                                                                                                                     logDate: "...",
                                                                                                                     name: "...",
                                                                                                                     objectType: Log.objectType,
                                                                                                                     objectId: .init(),
                                                                                                                     logTags: ["Tag1", "Tag2"],
                                                                                                                     logLabels: logLabels,
                                                                                                                     logHost: nil)))),
            
            // MARK: - TEST: Properties with dot names and properties specified as array
            ObjectFilterCondition(property: ObjectFilterProperty(["object", "object", "logLabels", "nestedObject", "logLabels", ".", ".", "hello"]),
                                  expression: ObjectFilterExpression(filterOperator: .Equals, op1: "hello")),
            
            // MARK: - Test: .LessThan, .LessThanOrEqual, .GreaterThan, .GreaterThanOrEqual
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThan, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThan, op1: "Abce")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThanOrEqual, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .LessThanOrEqual, op1: "ABc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThan, op1: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThan, op1: "abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThanOrEqual, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .GreaterThanOrEqual, op1: "Abc")),

            // MARK: - Test: .Between
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 42, op2: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 41, op2: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: 43, op2: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abc", op2: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abb", op2: "Abd")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Between, op1: "Abd", op2: "Abb")),

            // MARK: - Test: .NotBetween
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 43, op2: 47)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 47, op2: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: 41, op2: 41)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abd", op2: "Abf")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abf", op2: "Abd")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotBetween, op1: "Abb", op2: "Abb")),

            // MARK: - Test: .Like
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "Abc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "Ab_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_b_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "___")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%__")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%___")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "__%_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "_%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "__%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "___%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%bc")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%c")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "A%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%c")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%%")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "%a_c\\\\d\\_")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString1"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: ".*+?^${}()|[]")),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.filterLikeString2"),
                                  expression: ObjectFilterExpression(filterOperator: .Like, op1: "\\/")),
            
            // MARK: - Test: .Contains
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: 42)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [42])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [42, [43], [[46]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, 1])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, 1, 3, 1])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array2"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: [3, [3, 2]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.complexLog"),
                                  expression: ObjectFilterExpression(filterOperator: .Contains, op1: AnyCodable(simpleLog))),
            
            // MARK: - Test: .NotContains
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: 43)),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [41, [45], [[43]]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array1"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [3, 1, 5])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.array2"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: [3, [3, 1]])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.complexLog"),
                                  expression: ObjectFilterExpression(filterOperator: .NotContains, op1: AnyCodable(simpleLog2))),
             
            // MARK: - Test: .In
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, 42, "42"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, 42, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [43, true, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .In, op1: [
                                    Log(logLevel: .info,
                                        logMessage: "ABC",
                                        logDate: "22.01.2001",
                                        name: "AbCC",
                                        objectType:
                                        Log.objectType,
                                        objectId: thirdObject.objectId,
                                        logTags: ["Tag1", "Tag2"],
                                        logLabels: logLabels,
                                        logHost: nil),
                                    Log(logLevel: .info,
                                        logMessage: "Dummy",
                                        logDate: "2.2.2020")
                                  ])),

            // MARK: - Test: .NotIn
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.number"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, 41, "42"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.string"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, 42, "abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object.logLabels.boolean"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [43, false, "Abc"])),
            ObjectFilterCondition(property: ObjectFilterProperty("object.object"),
                                  expression: ObjectFilterExpression(filterOperator: .NotIn, op1: [
                                    Log(logLevel: .info,
                                        logMessage: "ABC",
                                        logDate: "22.01.2001",
                                        // Only name property is not the same as in object.object
                                        name: "AbCCC",
                                        objectType:
                                        Log.objectType,
                                        objectId: thirdObject.objectId,
                                        logTags: ["Tag1", "Tag2"],
                                        logLabels: logLabels,
                                        logHost: nil),
                                    Log(logLevel: .info,
                                        logMessage: "Dummy",
                                        logDate: "2.2.2020")
                                  ])),
            
        ]
        
        filter = ObjectFilter(conditions: ObjectFilterConditions(or: conditions))
        
        // Edge case
        filter.condition = singleCondition
        
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
    }
    
    func testEmptyParametersList() throws {
        let obj = CoatyObject(coreType: .Log,
                              objectType: Log.objectType,
                              objectId: .init(),
                              name: "Hello")
        
        let filter = ObjectFilter(condition: ObjectFilterCondition(property: ObjectFilterProperty(""),
                                                                   expression: ObjectFilterExpression(filterOperator: .Equals,
                                                                                                      op1: "Hello")))
        
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: obj, filter: filter))
    }
    
    func testTooShortParametersList() throws {
        let thirdObject = Log(logLevel: .info,
                              logMessage: "ABC",
                              logDate: "22.01.2001",
                              name: "AbCC",
                              objectType: Log.objectType,
                              objectId: .init(),
                              logTags: ["Tag1", "Tag2"])
        
        let secondObject = Snapshot(creationTimestamp: 1.0,
                                    creatorId: .init(),
                                    object: thirdObject)
        
        let firstObject = Snapshot(creationTimestamp: 2.0,
                                   creatorId: .init(),
                                   object: secondObject)
        
        // Shorter list than should be
        let filter = ObjectFilter(condition: ObjectFilterCondition(property: ObjectFilterProperty("object."),
                                                                   expression: ObjectFilterExpression(filterOperator: .Equals,
                                                                                                      op1: "Hello")))
        
        XCTAssertFalse(ObjectMatcher.matchesFilter(obj: firstObject, filter: filter))
    }
    
    func testNoConditions() throws {
        let obj = CoatyObject(coreType: .Log,
                              objectType: Log.objectType,
                              objectId: .init(),
                              name: "Hello")
        
        let filter = ObjectFilter(condition: ObjectFilterCondition(property: ObjectFilterProperty("name"),
                                                                   expression: ObjectFilterExpression(filterOperator: .Equals,
                                                                                                      op1: "Hello")))
        
        // Edge case
        filter.condition = nil
        
        XCTAssertTrue(ObjectMatcher.matchesFilter(obj: obj, filter: filter))

    }
}
