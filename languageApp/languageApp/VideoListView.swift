import SwiftUI

struct VideoListView: View {
    var body: some View {
        // Wrapping UIKit controller inside SwiftUI NavigationView
        NavigationView {
            VideoListViewControllerWrapper()
                .edgesIgnoringSafeArea(.all) // Use the entire screen
                .navigationBarHidden(true) // Hide SwiftUI navigation bar, use UIKit's
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// Structure wrapping the UIKit controller
struct VideoListViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = VideoListViewController()
        
        // Place inside UINavigationController
        // so that the buttons will be visible
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.prefersLargeTitles = true
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Updates handled by the view controller itself
    }
}
