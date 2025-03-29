import Foundation
import Combine
import UIKit

class BlogService: ObservableObject {
    @Published var posts: [BlogPost] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let apiKey = "4ce0e9bb154143fd93adb74ec405a2eb"
    
    func fetchCertikBlogPosts() {
        isLoading = true
        error = nil
        
        let urlString = "https://newsapi.org/v2/everything?q=wallet%20security%20OR%20crypto%20security&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            self.error = URLError(.badURL)
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    return
                }
                
                guard let data = data else {
                    self?.error = URLError(.badServerResponse)
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    struct NewsResponse: Codable {
                        let status: String
                        let totalResults: Int
                        let articles: [Article]
                    }
                    
                    struct Article: Codable {
                        let source: Source
                        let title: String
                        let description: String?
                        let url: String
                        let urlToImage: String?
                        let publishedAt: String
                        let content: String?
                    }
                    
                    struct Source: Codable {
                        let id: String?
                        let name: String
                    }
                    
                    let newsResponse = try decoder.decode(NewsResponse.self, from: data)
                    
                    // Convert News API articles to our BlogPost model
                    self?.posts = newsResponse.articles.map { article in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        let date = dateFormatter.date(from: article.publishedAt) ?? Date()
                        
                        let post = BlogPost(
                            id: UUID(),
                            title: article.title,
                            content: article.description ?? article.content ?? "",
                            date: date,
                            category: self?.determineCategory(from: article.title, description: article.description ?? "") ?? .news,
                            imageURL: article.urlToImage ?? "lock.shield"
                        )
                        return post
                    }
                } catch {
                    print("Decoding error: \(error)")
                    // If we can't fetch from the API, use sample data
                    self?.posts = self?.createSamplePosts() ?? []
                }
            }
        }.resume()
    }
    
    private func determineCategory(from title: String, description: String) -> BlogPost.Category {
        let text = (title + " " + description).lowercased()
        
        if text.contains("guide") || text.contains("tutorial") || text.contains("how to") {
            return .guide
        } else if text.contains("security") || text.contains("hack") || text.contains("breach") {
            return .security
        } else if text.contains("tip") || text.contains("best practice") || text.contains("recommendation") {
            return .tips
        } else {
            return .news
        }
    }
    
    private func createSamplePosts() -> [BlogPost] {
        return [
            BlogPost(
                id: UUID(),
                title: "Understanding Mnemonics",
                content: "Learn how to create and use secure mnemonic phrases for your cryptocurrency wallets. This guide covers best practices and security considerations.",
                date: Date(),
                category: .guide,
                imageURL: "lock.shield.fill"
            ),
            BlogPost(
                id: UUID(),
                title: "Essential Security Tips",
                content: "Protect your digital assets with these essential security tips. From hardware wallets to 2FA, learn how to keep your crypto safe.",
                date: Date().addingTimeInterval(-86400),
                category: .security,
                imageURL: "shield.fill"
            ),
            BlogPost(
                id: UUID(),
                title: "Secure Storage Guide",
                content: "Discover the best practices for storing your cryptocurrency securely. This comprehensive guide covers cold storage, backup strategies, and more.",
                date: Date().addingTimeInterval(-172800),
                category: .tips,
                imageURL: "lock.square.fill"
            )
        ]
    }
} 
