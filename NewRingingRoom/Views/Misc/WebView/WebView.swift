import SwiftUI
import WebKit

struct WebView: View {
    static var privacy = WebView(url: "https://ringingroom.com/privacy", showControls: false)
    
    @ObservedObject var model: WebViewModel
    
    init(url: String, showControls: Bool) {
        self.model = WebViewModel(progress: 0.0, link: url)
        self.showControls = showControls
    }
    
    var showControls: Bool
    
    @State var actionSheetIsPresented = false
    
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
                        ShareSheet(activityItems: [URL(string: model.link)!], applicationActivities: nil)
                    }
                    
                    Spacer()
                    
                    Button {
                        UIApplication.shared.open(URL(string: model.link)!)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
                .padding()
            }
        }
    }
}
