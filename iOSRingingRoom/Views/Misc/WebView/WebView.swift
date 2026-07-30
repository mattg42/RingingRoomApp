import SwiftUI
import WebKit

struct WebView: View {
    static var privacy: WebView {
        WebView(url: "https://ringingroom.com/privacy", showControls: false)
    }
    
    @StateObject private var model: WebViewModel
    
    init(url: String, showControls: Bool) {
        _model = StateObject(wrappedValue: WebViewModel(progress: 0.0, link: url))
        self.showControls = showControls
    }
    
    var showControls: Bool
    
    @State private var actionSheetIsPresented = false
    
    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    VStack {
                        SwiftUIWebView(viewModel: model)
                    }
                    
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(Color.black)
                            .opacity(0.2)
                        
                        Rectangle()
                            .fill(Color.main)
                            .frame(width: geo.size.width*CGFloat(model.progress))
                    }
                    .opacity(model.alpha)
                    .frame(height: 5)
                }
            }
            
            if showControls {
                HStack {
                    Button {
                        model.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    
                    Spacer()
                    
                    Button {
                        model.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    
                    Spacer()
                    
                    Button {
                        actionSheetIsPresented = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .sheet(isPresented: $actionSheetIsPresented) {
                        if let url = URL(string: model.link) {
                            ShareSheet(activityItems: [url], applicationActivities: nil)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        guard let url = URL(string: model.link) else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
                .padding()
            }
        }
    }
}
