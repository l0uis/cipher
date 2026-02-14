import Foundation

enum AppConstants {
    enum API {
        // Backend server URL - change to your deployed URL in production
        static let serverBaseURL = "https://cipher-production-def0.up.railway.app"

        static let metMuseumBaseURL = "https://collectionapi.metmuseum.org/public/collection/v1"
    }

    enum Image {
        static let maxImageDimension: CGFloat = 768
        static let jpegCompressionQuality: CGFloat = 0.4
        static let thumbnailSize: CGFloat = 200
        static let scanImageDirectory = "ScanImages"
    }

    enum UI {
        static let maxEnrichmentResults = 5
    }
}
