//  Copyright (c) 2020 Siemens AG. Licensed under the MIT License.
//
//  RuleBasedIoRouter.swift
//  CoatySwift
//
//

import Foundation

/// Supports rule-based routing of data from IO sources to IO actors based on an
/// associated IO context.
///
/// Define rules that determine whether a given pair of IO source and IO actor
/// should be associated or not. A rule is only applied if the value type of IO
/// source and IO actor are compatible. If no rules are defined or no rule
/// matches no associations between IO sources and IO actors are established.
///
/// You can define global rules that match IO sources and actors of any
/// compatible value type or value-type specific rules that are only applied to
/// IO sources and IO actors with a given value type.
///
/// By default, an IO source and an IO actor are compatible if both define equal
/// value types in equal data formats. You can define your own custom
/// compatibility check on value types in a subclass by overriding the
/// `areValueTypesCompatible` method.
///
/// Note that this router makes its IO context available by advertising and for
/// discovery (by core type, object type, or object Id) and listens for
/// Update-Complete events on its IO context, triggering `onIoContextChanged`
/// automatically.
///
/// This router requires the following controller options:
/// - `ioContext`: the IO context for which this router is managing routes
///    (mandatory)
/// - `rules`: an array of rule definitions for this router. The rules listed
///    here override any rules defined in the `onInit` method.
public class RuleBasedIoRouter: IoRouter {
    
    // MARK: - Attributes.
    
    /// An array of current association items
    private var currentAssociations: [(IoSource, IoActor, Int)] = []
    
    /// Defined rules hashed by value type
    /// Key: String, Value: NSMutableArray of [IoAssociationRule] type
    /// NSMutableArray is used to be able to mutate the contents of the arrays mapped by Strings by using a reference to this array.
    private var rules: NSMutableDictionary = .init()
    
    // MARK: - Overridden lifecycle methods.
    
    public override func onInit() {
        super.onInit()
        self.currentAssociations = []
        self.rules = .init()
    }
    
    // MARK: - Overridden methods.
    
    /// Invoked when the IO context of this router has changed.
    ///
    /// Triggers reevaluation of all defined rules.
    override func onIoContextChanged() throws {
        try super.onIoContextChanged()
        self.evaluateRules()
    }
    
    // MARK: - Class methods.
    
    /// Define all association rules for routing.
    ///
    /// Note that any previously defined rules are discarded.
    ///
    /// Rules with undefined condition function are ignored.
    ///
    /// - Parameter rules: association rules for this IO router
    func defineRules(rules: [IoAssociationRule]) {
        self.rules.removeAllObjects()
        
        rules.forEach { rule in
            let valueType = rule.valueType ?? ""
            var vRules = self.rules[valueType] as? NSMutableArray
            if vRules == nil {
                vRules = .init()
                self.rules[valueType] = vRules!
            }
            /// Force unwrapping is safe, since we are sure that vRules is not nil at this point.
            vRules!.add(rule)
        }
        
        self.evaluateRules()
    }
    
    override func onStarted() {
        if let rules = self.options?.extra["rules"] as? [IoAssociationRule] {
            self.defineRules(rules: rules)
        }
        
        super.onStarted()
    }
    
    override func onStopped() {
        // Disassociate all associations
        self.currentAssociations.forEach { source, actor, _ in
            try? self.disassociate(source: source, actor: actor)
        }
        
        self.currentAssociations = []
        
        super.onStopped()
    }
    
    /// The default function used to compute the recommended update rate of an
    /// individual IO source - IO actor association.
    ///
    /// This function takes into account the maximum possible update rate of the
    /// source and the desired update rate of the actor and returns a value that
    /// satisfies both rates.
    ///
    /// Override this method in a subclass to implement a custom rate function.
    ///
    /// - Parameters:
    ///     - source: the IoSource object
    ///     - actor the IoActor object
    ///     - sourceNode the IO source's node
    ///     - sourceNode the IO actor's node
    func computeDefaultUpdateRate(source: IoSource,
                                  actor: IoActor,
                                  sourceNode: IoNode,
                                  actorNode: IoNode) -> Int {
        if source.updateRate == nil {
            return actor.updateRate!
        }
        if actor.updateRate == nil {
            return source.updateRate!
        }
        return max(source.updateRate!, actor.updateRate!)
    }
    
    override func onIoNodeManaged(node: IoNode) {
        self.evaluateRules()
    }
    
    override func onIoNodesUnmanaged(nodes: [IoNode]) {
        self.evaluateRules()
    }
    
    func evaluateRules() {
        self.act(resolvedPairs: self.resolve(associationMap: self.match(compatibleAssociations: self.getCompatibleAssociations())))
    }
    
    func getCompatibleAssociations() -> [IoCompatibleAssociation] {
        var compatibleAssociations: [IoCompatibleAssociation] = []
        /// Key: CoatyUUID, Value: (IoSource, IoNode)
        let sources = NSMutableDictionary()
        /// Key: CoatyUUID, Value: (IoActor, IoNode)
        let actors = NSMutableDictionary()
        
        self.managedIoNodes.forEach { _, value in
            let node = value as! IoNode
            node.ioSources.forEach { src in
                sources[src.objectId.string] = (src, node)
            }
            node.ioActors.forEach { actor in
                actors[actor.objectId.string] = (actor, node)
            }
        }
        
        sources.forEach { _, value in
            let (source, sourceNode) = value as! (IoSource, IoNode)
            actors.forEach { _, value in
                let (actor, actorNode) = value as! (IoActor, IoNode)
                if self.areValueTypesCompatible(source: source, actor: actor) {
                    compatibleAssociations.append(IoCompatibleAssociation(source, sourceNode, actor, actorNode))
                }
            }
        }
        
        return compatibleAssociations
    }
    
    func match(compatibleAssociations: [IoCompatibleAssociation]) -> IoAssociationPairs {
        let associationMap = IoAssociationPairs.init()
        
        compatibleAssociations.forEach { source, sourceNode, actor, actorNode in
            var valueType = source.valueType
            var rules = self.rules[valueType] as? NSMutableArray
            if rules == nil {
                // Apply global rules
                valueType = ""
                rules = self.rules[valueType] as? NSMutableArray
            }
            if let rules = rules {
                let len = rules.count
                for index in 0...len-1 {
                    /// Force cast is safe since this NSMutableArraay only contains IoAssociationRule objects
                    let rule = rules[index] as! IoAssociationRule
                    
                    guard let isMatch = rule.condition(source, sourceNode, actor, actorNode, self.ioContext, self) else {
                        let logger = LogManager.log
                        logger.error("RuleBasedIoRouter: failed invoking condition of rule. Returned value is nil.")
                        continue
                    }
                    
                    if isMatch {
                        var actors = associationMap[source.objectId.string] as? NSMutableDictionary
                        
                        if actors == nil {
                            actors = .init()
                            associationMap[source.objectId.string] = actors!
                        }
                        let value = IoAssociationInfo(source,
                                                      actor,
                                                      self.computeCumulatedUpdateRate(rate1: source.updateRate, rate2: actor.updateRate))
                        /// Force unwrapping is safe, since we are sure that `actors` is not nil at this point.
                        actors![actor.objectId.string] = value
                        
                        // No need to check remaining rules after the first match
                        break
                    }    
                }
            }
        }
        
        return associationMap
    }
    
    func resolve(associationMap: IoAssociationPairs) -> IoAssociationPairs {
        // Compute cumulated update rates for each resolved IO source.
        associationMap.forEach { _, value in
            /// Force cast is safe safe, since the values of associationMap are all of type NSMutableDictionary
            let actors = value as! NSMutableDictionary
            var cumulatedRate: Int = .init()
            actors.forEach { _, value in
                let tuple = value as! IoAssociationInfo
                let rate = tuple.2
                cumulatedRate = self.computeCumulatedUpdateRate(rate1: rate, rate2: cumulatedRate)
            }
            actors.forEach { key, value in
                var info = value as! IoAssociationInfo
                info.2 = cumulatedRate
                
                /// Tuples are pass by value in Swift, so we need to explicitly mutate the dictionary at the key, so that a change in this tuple is persisted.
                actors[key] = info
            }
        }
        
        return associationMap
    }
    
    func act(resolvedPairs: IoAssociationPairs) {
        var newAssociations = [IoAssociationInfo].init()
        
        self.currentAssociations.forEach { source, actor, rate in
            if let resolvedActors = resolvedPairs[source.objectId.string] as? NSMutableDictionary {
                if let resolvedInfo = resolvedActors[actor.objectId.string] as? IoAssociationInfo {
                    let (resolvedSrc, resolvedAct, resolvedRate) = resolvedInfo
                    if resolvedRate != rate {
                        // Keep the current association but with the new update rate.
                        try? self.associate(source: resolvedSrc, actor: resolvedAct, updateRate: resolvedRate)
                    }
                    newAssociations.append(IoAssociationInfo(resolvedSrc, resolvedAct, resolvedRate))
                    
                    // Remove the resolved pair so that remaining
                    // pairs can be identified as being new associations.
                    resolvedActors.removeObject(forKey: actor.objectId.string)
                    if resolvedActors.count == 0 {
                        resolvedPairs.removeObject(forKey: source.objectId.string)
                    }
                } else {
                    try? self.disassociate(source: source, actor: actor)
                }
            } else {
               try? self.disassociate(source: source, actor: actor)
            }
            
        }
        
        // Add the remaining resolved pairs as new associations.
        resolvedPairs.forEach { _, value in
            let newActors = value as! NSMutableDictionary
            newActors.forEach { _, value in
                let (src, act, rate) = value as! IoAssociationInfo
                try? self.associate(source: src, actor: act, updateRate: rate)
                newAssociations.append(IoAssociationInfo(src, act, rate))
            }
        }
        
        self.currentAssociations = newAssociations
    }
    
    func computeCumulatedUpdateRate(rate1: Int?, rate2: Int?) -> Int {
        if rate1 != nil {
            if rate2 != nil {
                return max(rate2!, rate1!)
            } else {
                return rate1!
            }
        }
        return rate2!
    }
}

// MARK: - Additional type declarations.

/// Condition function type for IO routing rules.
public typealias IoRoutingRuleConditionFunc = (
    _ source: IoSource,
    _ sourceNode: IoNode,
    _ actor: IoActor,
    _ actorNode: IoNode,
    _ context: IoContext,
    _ router: RuleBasedIoRouter) -> Bool?

/// Defines a rule for associating IO sources with IO actors.
public struct IoAssociationRule {
    /// The name of the rule. Used for display purposes only.
    var name: String
    
    /// The value type for which the rule is applicable. The rule is applied to
    /// all IO source - IO actor pairs whose value type matches this value type.
    ///
    /// If the value type is nil or an empty string, the rule acts as a
    /// global rule. It applies to all IO source - IO actor pairs that have
    /// compatible value types. Non-global rules have precedence over global
    /// rules. Global rules only apply if there are no non-global rules whose
    /// value type matches the value type of the corresponding IO source - IO
    /// actor pair.
    var valueType: String?
    
    /// The rule condition function.
    ///
    /// When applied, the condition function is passed a pair of value-compatible
    /// IO source and actor that are eligible for association.
    ///
    /// The condition function should return true if the passed-in association
    /// pair should be associated; false or nil otherwise.
    ///
    /// Eventually, an association pair is associated if there is at least one
    /// applicable rule that returns true; otherwise the association pair
    /// is not associated, i.e. it is actively disassociated if currently
    /// associated.
    var condition: IoRoutingRuleConditionFunc
    
    /// All public structs need public inits, otherwise the compiler sees them as internal.
    public init(name: String, valueType: String?, condition: @escaping IoRoutingRuleConditionFunc) {
        self.name = name
        self.valueType = valueType
        self.condition = condition
    }
}

/// Maps value types to an array of compatible IO source - IO source node - IO
/// actor - IO actor node pairs.
typealias IoCompatibleAssociation = (IoSource, IoNode, IoActor, IoNode)

/// A tuple describing an association pair with its update rate.
typealias IoAssociationInfo = (IoSource, IoActor, Int)

/// Maps source IDs to a map of actor IDs with IoAssociationInfo tuples.
/// Key: CoatyUUID, Value: NSMutableDictionary of: Key: CoatyUUID, Value: IoAssociationInfo
typealias IoAssociationPairs = NSMutableDictionary
