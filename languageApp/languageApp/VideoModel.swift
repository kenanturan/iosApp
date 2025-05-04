// Channel response models
struct ChannelResponse: Codable {
    let items: [ChannelItem]
}

struct ChannelItem: Codable {
    let contentDetails: ContentDetails
}

struct ContentDetails: Codable {
    let relatedPlaylists: RelatedPlaylists
}

struct RelatedPlaylists: Codable {
    let uploads: String
}

// Playlist response models
struct PlaylistResponse: Codable {
    let items: [PlaylistItem]
    let nextPageToken: String?
}

struct PlaylistItem: Codable {
    let snippet: PlaylistItemSnippet
}

struct PlaylistItemSnippet: Codable {
    let title: String
    let description: String
    let publishedAt: String
    let thumbnails: Thumbnails
    let resourceId: ResourceId
}

struct ResourceId: Codable {
    let videoId: String
}

struct Thumbnails: Codable {
    let medium: ThumbnailInfo
}

struct ThumbnailInfo: Codable {
    let url: String
}
