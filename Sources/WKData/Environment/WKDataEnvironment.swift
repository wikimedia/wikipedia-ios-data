import Foundation

public struct WKAppData {
    let appLanguages: [WKLanguage]
    
    public init(appLanguages: [WKLanguage]) {
        self.appLanguages = appLanguages
    }
}

public final class WKDataEnvironment: ObservableObject {

	public static let current = WKDataEnvironment()

    @Published public var appData = WKAppData(appLanguages: [])
    @Published public var mediaWikiService: WKService?
}
