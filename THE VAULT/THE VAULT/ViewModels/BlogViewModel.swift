import Foundation
import Combine

class BlogViewModel: ObservableObject {
    @Published var posts: [BlogPost] = []
    @Published var selectedCategory: BlogPost.Category?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let blogService = BlogService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSamplePosts()
        Task {
            await fetchCertikPosts()
        }
    }
    
    private func loadSamplePosts() {
        posts = [
            BlogPost(
                id: UUID(),
                title: "How to Secure Your Crypto Wallet",
                content: "Learn the best practices for securing your cryptocurrency wallet and protecting your digital assets.",
                date: Date().addingTimeInterval(-86400),
                category: .security,
                imageURL: "lock.shield.fill"
            ),
            BlogPost(
                id: UUID(),
                title: "Understanding Mnemonics",
                content: "A comprehensive guide to understanding and using mnemonic phrases for wallet recovery.",
                date: Date().addingTimeInterval(-172800),
                category: .guide,
                imageURL: "lock.fill"
            ),
            BlogPost(
                id: UUID(),
                title: "Top Security Tips",
                content: "Essential security tips to keep your cryptocurrency safe and secure.",
                date: Date().addingTimeInterval(-259200),
                category: .tips,
                imageURL: "shield.fill"
            ),
            BlogPost(
                id: UUID(),
                title: "Latest Security News",
                content: "Stay updated with the latest news in cryptocurrency security and best practices.",
                date: Date().addingTimeInterval(-345600),
                category: .news,
                imageURL: "lock.square.fill"
            )
        ]
    }
    
    @MainActor
    func fetchCertikPosts() async {
        isLoading = true
        blogService.fetchCertikBlogPosts()
        
        blogService.$posts
            .sink { [weak self] newPosts in
                self?.posts = self?.posts.filter { $0.imageURL?.hasPrefix("http") == false } ?? []
                self?.posts.append(contentsOf: newPosts)
                self?.isLoading = false
            }
            .store(in: &cancellables)
        
        blogService.$error
            .sink { [weak self] error in
                self?.error = error
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    var filteredPosts: [BlogPost] {
        guard let category = selectedCategory else {
            return posts
        }
        return posts.filter { $0.category == category }
    }
} 