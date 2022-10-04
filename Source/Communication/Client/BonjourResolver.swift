//  Copyright (c) 2019 Siemens AG. Licensed under the MIT License.
//
//  BonjourResolver.swift
//  CoatySwift
//
//

import Foundation

/// This class provides Bonjour-based broker discovery and calls
/// its delegate when it has found new services.
class BonjourResolver: NSObject {
 
    // MARK: - Attributes.
 
    private let log = LogManager.log
    private let browser = NetServiceBrowser()
    private var brokerService: NetService? = nil
    var delegate: BonjourResolverDelegate? = nil

    override init() {
        super.init()
 
        // Set NetService browser delegate.
        browser.delegate = self
    }
 
    // MARK: - Helper methods.
 
    public func startDiscovery() {
        stopDiscovery()
 
        browser.searchForServices(ofType: BonjourConfiguration.serviceType,
                                  inDomain: BonjourConfiguration.serviceDomain)
 
    }
 
    public func stopDiscovery() {
        browser.stop()
    }
 
}

// MARK: - NetServiceBrowserDelegate extension.

extension BonjourResolver: NetServiceBrowserDelegate {
 
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        log.debug("Did find net service.")
 
        // Has to be saved here, otherwise we lose reference and cannot resolve.
        brokerService = service
        
        // Add delegate for resolving later.
        brokerService?.delegate = self
 
        // Starting the service resolve.
        service.resolve(withTimeout: 5)
 
    }
 
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        log.debug("Did not search net service.")
    }
}

// MARK: - NetServiceDelegate extension.

extension BonjourResolver: NetServiceDelegate {
 
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        log.debug("Did remove net service.")
    }
 
    func netServiceDidResolveAddress(_ sender: NetService) {
 
        log.debug("Did resolve net service address.")
 
        // Find the IPV4 address.
        guard let serviceIPs = resolveIPv4Addresses(addresses: sender.addresses!) else {
            log.error("Could not find IPV4 addresses.")
            return
        }
 
        delegate?.didReceiveService(addresses: serviceIPs, port: sender.port)
    }
 
    // MARK: - Message parsing methods.
 
    /// Returns all IPv4 addresses for a service.
    /// - Note: Has been taken and adapted from https://sosedoff.com/2018/03/23/zeroconf-swift.html.
    func resolveIPv4Addresses(addresses: [Data]) ->  [String]? {
        var results = [String]()
 
        for addr in addresses {
            let data = addr as NSData
            var storage = sockaddr_storage()
            data.getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)
 
            if Int32(storage.ss_family) == AF_INET {
                let addr4 = withUnsafePointer(to: &storage) {
                    $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                        $0.pointee
                    }
                }
 
                if let ip = String(cString: inet_ntoa(addr4.sin_addr), encoding: .ascii) {
                    results.append(ip)
                } else {
                    return nil
                }
            }
        }
        return results
    }
 
}

