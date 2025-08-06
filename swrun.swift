#!/usr/bin/env swift

//
//  PrintBootCampESDInfo.swift
//
//  Created by nuomi1 on 8/5/18.
//  Copyright © 2018年 nuomi1. All rights reserved.
//

import Foundation

struct Catalog: Decodable {
    let catalogVersion: Int
    let applePostURL: String
    let indexDate: Date
    let products: [String: Product]

    struct Product: Decodable {
        let serverMetadataURL: String?
        let deferredSUEnablementDate: Date?
        let state: String?
        let packages: [Package]
        let extendedMetaInfo: ExtendedMetaInfo?
        let postDate: Date
        let distributions: [String: String]

        struct ExtendedMetaInfo: Decodable {
            let productType: String?
            let bridgeOSPredicateProductOrdering: String?
            let bridgeOSSoftwareUpdateEventRecordingServiceURL: String?
            let autoUpdate: String?
            let productVersion: String?
            let installAssistantPackageIdentifiers: InstallAssistantPackageIdentifiers?

            struct InstallAssistantPackageIdentifiers: Decodable {
                let sharedSupport: String?
                let installInfo: String
                let info: String?
                let updateBrain: String?
                let buildManifest: String?
                let osInstall: String?
            }
        }

        struct Package: Decodable {
            let digest: String?
            let size: Int
            let integrityDataURL: String?
            let metadataURL: String?
            let url: String
            let integrityDataSize: Int?
        }
    }
}

extension Catalog {
    enum CodingKeys: String, CodingKey {
        case catalogVersion = "CatalogVersion"
        case applePostURL = "ApplePostURL"
        case indexDate = "IndexDate"
        case products = "Products"
    }
}

extension Catalog.Product {
    enum CodingKeys: String, CodingKey {
        case serverMetadataURL = "ServerMetadataURL"
        case deferredSUEnablementDate = "DeferredSUEnablementDate"
        case state = "State"
        case packages = "Packages"
        case extendedMetaInfo = "ExtendedMetaInfo"
        case postDate = "PostDate"
        case distributions = "Distributions"
    }
}

extension Catalog.Product.ExtendedMetaInfo {
    enum CodingKeys: String, CodingKey {
        case productType = "ProductType"
        case bridgeOSPredicateProductOrdering = "BridgeOSPredicateProductOrdering"
        case bridgeOSSoftwareUpdateEventRecordingServiceURL = "BridgeOSSoftwareUpdateEventRecordingServiceURL"
        case autoUpdate = "AutoUpdate"
        case productVersion = "ProductVersion"
        case installAssistantPackageIdentifiers = "InstallAssistantPackageIdentifiers"
    }
}

extension Catalog.Product.ExtendedMetaInfo.InstallAssistantPackageIdentifiers {
    enum CodingKeys: String, CodingKey {
        case sharedSupport = "SharedSupport"
        case installInfo = "InstallInfo"
        case info = "Info"
        case updateBrain = "UpdateBrain"
        case buildManifest = "BuildManifest"
        case osInstall = "OSInstall"
    }
}

extension Catalog.Product.Package {
    enum CodingKeys: String, CodingKey {
        case digest = "Digest"
        case size = "Size"
        case integrityDataURL = "IntegrityDataURL"
        case metadataURL = "MetadataURL"
        case url = "URL"
        case integrityDataSize = "IntegrityDataSize"
    }
}

let sucatalog = "https://swscan.apple.com/content/catalogs/others/index-15-14-13-12-10.16-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog.gz"

let catalog = {
    let data = try! Data(contentsOf: URL(string: sucatalog)!)
    let decoder = PropertyListDecoder()
    let catalog = try! decoder.decode(Catalog.self, from: data)
    return catalog
}()

func matches(for regex: String, in text: String) -> [String] {
    let regex = try! NSRegularExpression(pattern: regex)
    let range = NSRange(text.startIndex..., in: text)
    let results = regex.matches(in: text, range: range)
    let texts = results.map { (text as NSString).substring(with: $0.range(at: 1)) }
    return texts
}

func printBootCampESDInfo() {
    let products = catalog.products
        .filter { $0.value.packages.contains { $0.url.hasSuffix("BootCampESD.pkg") }}
        .sorted(by: { $0.key < $1.key })

    for (id, product) in products {
        let infoUrl = URL(string: product.distributions.values.first!)!

        print(id)
        print(product.postDate)
        printModelsInfo(infoUrl)

        for package in product.packages {
            print(package.url)
        }

        print()
    }
}

func printModelsInfo(_ url: URL) {
    let data = try! Data(contentsOf: url)
    let text = String(data: data, encoding: .utf8)!

    let models = matches(for: #"(\w{1,}\d{1,},\d{1,})"#, in: text)

    for model in models {
        print(model)
    }
}

func printInstallESDDmgInfo() {
    let products = catalog.products
        .filter { $0.value.extendedMetaInfo?.installAssistantPackageIdentifiers?.installInfo == "com.apple.plist.InstallInfo" }
        .sorted(by: { $0.key < $1.key })

    for (id, product) in products {
        let infoUrl = URL(string: product.distributions.values.first!)!
        let packages = product.packages.sorted(by: { $0.url < $1.url })

        print(id)
        print(product.postDate)
        printSystemInfo(infoUrl)

        for package in packages {
            if ["InstallAssistantAuto.pkg", "RecoveryHDMetaDmg.pkg", "InstallESDDmg.pkg", "InstallAssistant.pkg"].contains(where: package.url.hasSuffix) {
                print(package.url)
            }
        }

        print()
    }
}

func printSystemInfo(_ url: URL) {
    let data = try! Data(contentsOf: url)
    let text = String(data: data, encoding: .utf8)!

    let build = matches(for: #"<key>BUILD</key>\n *<string>(.*)</string>"#, in: text)[0]
    let version = matches(for: #"<key>VERSION</key>\n *<string>(.*)</string>"#, in: text)[0]
    let system = matches(for: #"suDisabledGroupID="([\w\s]+)""#, in: text)[0]

    print(system, version, build)
}

print("BootCamp")
print()
printBootCampESDInfo()

print()

print("InstallESDDmg")
print()
printInstallESDDmgInfo()
