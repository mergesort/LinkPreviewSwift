//
//  LinkPreviewTests.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 1/19/25.
//

import Foundation
import LinkPreview
import SwiftSoup
import Testing

@Suite
struct LinkPreviewTests {
    @Test func simpleFile() async throws {
        let provider = LinkPreviewProvider()
        let preview = try await provider.load(from: URL(string: "https://apple.com")!)
        #expect(preview.description != nil)
        #expect(preview.title != nil)
    }

    @Test func descriptionFallback() async throws {
        let provider = LinkPreviewProvider()
        let preview = try await provider.load(html: """
        <head>
        <meta property="og:title" content="Title" />
        <meta name="description" content="Hello, world" />
        </head>
        """, url: URL(string: "https://example.com")!)
        #expect(preview.title == "Title")
        #expect(preview.description == "Hello, world")
    }

    @Test func titleFallback() async throws {
        let provider = LinkPreviewProvider()
        let preview = try await provider.load(html: """
        <head>
        <title>Title</title>
        <meta name="description" content="Hello, world" />
        </head>
        """, url: URL(string: "https://example.com")!)
        #expect(preview.title == "Title")
        #expect(preview.description == "Hello, world")
    }

    @Test func dropbox() async throws {
        let provider = LinkPreviewProvider()
        let preview = try await provider.load(from: URL(string: "https://www.dropbox.com/scl/fi/9zhr8oqh8d49vgkvtn6jo/IMG_3996.HEIC?rlkey=iw62xieb2yrxtn0ujczl2lmkb&st=yq524xne&dl=0")!)
        #expect(preview.description != nil)
    }

    @Test func wikipedia() async throws {
        let provider = LinkPreviewProvider()
        let url = URL(string: "https://en.wikipedia.org/wiki/Italian_language")!
        let preview = try await provider.load(from: url)
        #expect(preview.description != nil)
    }

    @Test func wikipediaNoAdditionalRequests() async throws {
        let provider = LinkPreviewProvider()
        provider.options.allowAdditionalRequests = false
        let url = URL(string: "https://en.wikipedia.org/wiki/Italian_language")!
        let preview = try await provider.load(from: url)

        // We'll use the short description here
        #expect(preview.description == "Romance language")
    }

    @Test func spotify() async throws {
        let provider = LinkPreviewProvider()
        let preview = try await provider.load(from: URL(string: "https://open.spotify.com/track/5TFD2bmFKGhoCRbX61nXY5")!)
        #expect(preview.audioURL != nil)
    }

    @Test func semana() async throws {
        let provider = LinkPreviewProvider()
        let preview = try await provider.load(from: URL(string: "https://www.semana.com/quien-remplaza-presidente-vicepresidente/265823-3/")!)
        #expect(preview.description != nil)
    }

    @Test func relativeImageURL() async throws {
        let provider = LinkPreviewProvider()
        let preview = try await provider.load(from: URL(string: "https://app.graphite.dev")!)
        let imageURL = try #require(preview.imageURL)
        #expect(imageURL.absoluteString.hasPrefix("https://app.graphite.dev"))
    }

    @Test func customProcessor() async throws {
        enum CustomProcessor: MetadataProcessor {
            static var activationRule: MetadataProcessorActivationRule {
                .always
            }

            static func updateLinkPreview(
                _ preview: inout LinkPreview,
                for url: URL,
                document: Document?,
                options: MetadataProcessingOptions
            ) async {
                var title = preview.title ?? ""
                if let host = url.host {
                    if !title.isEmpty {
                        title += " • "
                    }
                    title += host
                }
                if !title.isEmpty {
                    preview.title = title
                }
            }
        }

        let provider = LinkPreviewProvider()
        provider.registerProcessor(CustomProcessor.self)
        let preview = try await provider.load(html: """
            <head>
            <title>Example Domain</title>
            </head>
            """, url: URL(string: "https://example.com")!
        )
        #expect(preview.title == "Example Domain • example.com")
    }
}
