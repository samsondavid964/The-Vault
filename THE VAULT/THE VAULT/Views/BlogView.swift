import SwiftUI

struct BlogView: View {
    @StateObject private var viewModel = BlogViewModel()
    @State private var selectedCategory: BlogPost.Category?
    @State private var selectedPost: BlogPost?
    @State private var showPostDetail = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Featured Post
                    if let featuredPost = viewModel.posts.first {
                        FeaturedPostView(post: featuredPost) {
                            selectedPost = featuredPost
                            showPostDetail = true
                        }
                        .padding(.top, 8)
                    }
                    
                    // Search and Categories Section
                    VStack(spacing: 16) {
                        // Search Bar
                        HStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16, weight: .medium))
                                
                                TextField("Search articles...", text: $searchText)
                                    .font(.body)
                                    .focused($isSearchFocused)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            if !searchText.isEmpty {
                                Button(action: { 
                                    searchText = ""
                                    isSearchFocused = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 20))
                                }
                                .frame(width: 44, height: 44)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Categories
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                CategoryPill(
                                    title: "All",
                                    isSelected: selectedCategory == nil,
                                    action: { selectedCategory = nil }
                                )
                                
                                ForEach(BlogPost.Category.allCases, id: \.self) { category in
                                    CategoryPill(
                                        title: category.rawValue.capitalized,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .background(Color(.systemBackground))
                    
                    // Content List
                    LazyVStack(spacing: 20) {
                        ForEach(filteredPosts.dropFirst()) { post in
                            BlogPostCard(post: post)
                                .onTapGesture {
                                    selectedPost = post
                                    showPostDetail = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Security Blog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.fetchCertikPosts()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .sheet(isPresented: $showPostDetail) {
                if let post = selectedPost {
                    BlogPostDetailView(post: post)
                }
            }
            .refreshable {
                await viewModel.fetchCertikPosts()
            }
        }
    }
    
    private var filteredPosts: [BlogPost] {
        var posts = viewModel.posts
        
        if let category = selectedCategory {
            posts = posts.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            posts = posts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return posts
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .clipShape(Capsule())
        }
    }
}

struct FeaturedPostView: View {
    let post: BlogPost
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                Group {
                    if let imageURL = post.imageURL, imageURL.hasPrefix("http") {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color(.systemGray6))
                                    .overlay(ProgressView())
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Image(systemName: "newspaper.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(40)
                                    .foregroundColor(.blue)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "newspaper.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(40)
                            .foregroundColor(.blue)
                    }
                }
                .frame(height: 240)
                .clipped()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(post.category.rawValue.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text(post.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .lineSpacing(4)
                    
                    Text(post.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .lineSpacing(4)
                    
                    HStack {
                        Text(post.date, style: .date)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Read Article")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal)
    }
}

struct BlogPostCard: View {
    let post: BlogPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            Group {
                if let imageURL = post.imageURL, imageURL.hasPrefix("http") {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "newspaper.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(30)
                                .foregroundColor(.blue)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "newspaper.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(30)
                        .foregroundColor(.blue)
                }
            }
            .frame(height: 180)
            .clipped()
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(post.category.rawValue.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text(post.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .lineSpacing(4)
                
                Text(post.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .lineSpacing(4)
                
                Text(post.date, style: .date)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct BlogPostDetailView: View {
    let post: BlogPost
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image
                    Group {
                        if let imageURL = post.imageURL, imageURL.hasPrefix("http") {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color(.systemGray6))
                                        .overlay(ProgressView())
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Image(systemName: "newspaper.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(60)
                                        .foregroundColor(.blue)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "newspaper.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(60)
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(height: 280)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(post.category.rawValue.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        
                        Text(post.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                        
                        Text(post.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(post.content)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(8)
                    }
                    .padding(20)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .regular))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                let text = "\(post.title)\n\n\(post.content)"
                ShareSheet(activityItems: [text])
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    BlogView()
} 
