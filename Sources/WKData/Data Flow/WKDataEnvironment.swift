import Foundation

public struct WKAppData {

	let appLanguages: [String]

	public init(appLanguages: [String]) {
		self.appLanguages = appLanguages
	}

}

public final class WKDataEnvironment: ObservableObject {

	public static let current = WKDataEnvironment()

	@Published public private(set) var appData = WKAppData(appLanguages: ["English", "Spanish", "German"])
	@Published public private(set) var mediawikiNetworkService: WKNetworkService?

}
