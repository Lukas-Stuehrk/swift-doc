import Foundation
import SwiftDoc
import CommonMark
import HypertextLiteral

struct CustomDocumentationPage: Page {
    let baseURL: String
    let name: String
    let document: Document
    let title: String
    let module: Module
    let html: HTML

    init(module: Module, documentUrl: URL, baseURL: String) throws {
        self.baseURL = baseURL
        self.module = module
        let name = documentUrl.deletingPathExtension().lastPathComponent
        self.name = name
        let documentContents = String(decoding: try Data(contentsOf: documentUrl), as: UTF8.self)
        self.document = try Document(documentContents)
        self.html = "\(document)"
        self.title = TitleFinder(document: document).title ?? name
    }
}


/// We can simplify this and use a visitor when the `CommonMark` dependency is upgraded to version 0.5.0.
private class TitleFinder {
    var title: String?

    init(document: Document) {
        for child in document.children {
            walk(node: child)
            guard title == nil else { break }
        }
    }

    func walk(node: Node) {
        if let title = node as? Heading, title.level == 1 {
            self.title = title.textContents
            return
        }
        if let block = node as? ContainerOfBlocks {
            for child in block.children {
                walk(node: child)
                guard title == nil else { return }
            }
        }
    }
}

private extension Heading {
    var textContents: String {
        var text = ""
        for child in children {
            if let literal = child as? Literal, let additionalText = literal.literal {
                text += additionalText
            }
        }
        return text
    }
}
