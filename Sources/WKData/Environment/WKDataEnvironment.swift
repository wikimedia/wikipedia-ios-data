import Foundation

public final class WKDataEnvironment: ObservableObject {

	public static let current = WKDataEnvironment()

	@Published public private(set) var mediaWikiNetworkService: WKNetworkService?

}
