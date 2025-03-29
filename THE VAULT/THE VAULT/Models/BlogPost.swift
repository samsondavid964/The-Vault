import Foundation

struct BlogPost: Identifiable {
    let id: UUID
    let title: String
    let content: String
    let date: Date
    let category: Category
    let imageURL: String?
    
    enum Category: String, CaseIterable {
        case guide = "guide"
        case security = "security"
        case tips = "tips"
        case news = "news"
    }
    
    init(id: UUID = UUID(), title: String, content: String, date: Date = Date(), category: Category, imageURL: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.category = category
        self.imageURL = imageURL
    }
} 