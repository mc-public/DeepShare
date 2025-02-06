//
//  View+SearchBar.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/9.
//

import Foundation
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

/// A wrapper view for `UISearchBar` in SwiftUI from UIKit.
///
/// You can use the `focused(:)` modifier in SwiftUI to control whether the search bar is focused.
public struct SearchBar: UIViewRepresentable {
    
    @Binding private var text: String
    private let prompt: String
    
    /// Create an instance of a search bar.
    ///
    /// - Parameter text: Text displayed in the search bar.
    /// - Parameter isSearching: Indicates whether it is currently in a searching state.
    /// - Parameter prompt: Placeholder text displayed when the search bar is empty.
    public init(text: Binding<String>, prompt: String) {
        self._text = text
        self.prompt = prompt
    }

    public class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        init(text: Binding<String>) {
            _text = text
        }
        public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(true, animated: true)
        }
        public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(false, animated: true)
        }
        public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = String()
            text = String()
            searchBar.resignFirstResponder()
        }
    }
    
    public func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    public func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.text = self.text
        searchBar.placeholder = self.prompt
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = context.coordinator
        searchBar.autocapitalizationType = .none
        searchBar.inputAssistantItem.leadingBarButtonGroups = []
        searchBar.inputAssistantItem.trailingBarButtonGroups = []
        searchBar.inputAccessoryView = nil
        searchBar.autocorrectionType = .no
        return searchBar
    }

    public func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
        uiView.placeholder = prompt
    }
}

extension View {
    
    /// Insert a search bar at the top search area.
    ///
    /// - Parameter text: The relevant text passed during the search.
    /// - Parameter isSearching: Whether the current state is searching. Setting this value will change the current search state.
    /// - Parameter disabled: Whether to disable the search function. When disabled, the search bar will not be displayed.
    public func searchBar(text: Binding<String>, safeAreaInset: Bool = true, isSearching: Binding<Bool>, disabled: Bool = false) -> some View {
        self.modifier(NavigationTopSearchModified(searchText: text, isSearching: isSearching, isShowing: !disabled, isUseSafeAreaInset: safeAreaInset))
    }
}

public struct NavigationSearchBar: View {
    @Binding public var searchText: String
    @Binding public var isSearching: Bool
    public var isShowing: Bool
    @FocusState private var isFocus: Bool
    private var usingBackground: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    public init(searchText: Binding<String>, isSearching: Binding<Bool>, isShowing: Bool) {
        _searchText = searchText
        _isSearching = isSearching
        self.isShowing = isShowing
    }
    
    public init(text: Binding<String>, isSearching: Binding<Bool>, disabled: Bool = false) {
        _searchText = text
        _isSearching = isSearching
        isShowing = !disabled
        usingBackground = false
    }
    
    public var body: some View {
        let content = VStackLayout {
            HStack {
                /// Rounded Rectangle Background
//                RoundedRectangle(cornerSize: .init(width: 8, height: 8))
                Rectangle()
                    .fill(Material.ultraThick)
                    .shadow(radius: 0.7)
                    .frame(height: 36)
                    .overlay(alignment: .leading) {
                        self.searchBar()
                    }
                    .padding(.bottom)
                
                /// Cancel Button
                if self.isFocus {
                    Button("Cancel") {
                        withAnimation {
                            self.isFocus = false
                            self.isSearching = false
                            self.searchText = .init()
                        }
                    }
                    .bold()
                    .padding(.trailing)
                }
            }
        }
        Group {
            if self.isShowing {
                if usingBackground {
                    self.setBackground(content)
                } else {
                    content
                }
            }
        }
        .onChange(of: self.isFocus, initial: true) { _, newValue in
            self.isSearching = self.isFocus
            if !newValue {
                self.searchText = .init()
            }
        }
        .onChange(of: self.isSearching, initial: true) { _, newValue in
            self.isFocus = self.isSearching
            if !newValue {
                self.searchText = .init()
            }
        }
        .animation(.default, value: self.isFocus)
        .animation(.default, value: self.searchText)
        .animation(.default, value: self.isSearching)
        .animation(.default, value: self.isShowing)
    }
    
    @ViewBuilder
    private func searchBar() -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            /// Search Icon
            Image(systemName: "magnifyingglass")
                .padding(.leading, 10)
                .padding(.trailing, 3)
                .foregroundStyle(.secondary)
            /// Search
            TextField("Search", text: $searchText)
                .keyboardShortcutBarDisabled()
                .lineLimit(1)
                .focused(self.$isFocus)
                .padding(.trailing, 20)
            /// Clean Content Button
            if !self.searchText.isEmpty && self.isFocus {
                Button {
                    self.searchText = .init()
                } label: {
                    Image(systemName: "xmark.circle")
                        .imageScale(.small)
                        .foregroundStyle(.secondary)
                        .padding()
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    
    @ViewBuilder
    private func setBackground(_ view: @autoclosure () -> some View) -> some View {
        view().background {
            LinearGradient(colors: [
                self.setBackgroundStartColor().opacity(0.8),
                self.setBackgroundStartColor().opacity(0)
            ], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private func setBackgroundStartColor() -> Color {
        switch self.colorScheme {
            case .dark: Color(uiColor: UIColor.systemBackground)
            case .light: Color(uiColor: UIColor.systemBackground)
            @unknown default:
                Color.clear
        }
    }
}

fileprivate struct NavigationTopSearchModified: ViewModifier {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var isShowing: Bool
    var isUseSafeAreaInset: Bool
    @FocusState var isFocus: Bool
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        Group {
            if self.isUseSafeAreaInset {
                content
                    .safeAreaInset(edge: .top) {
                        NavigationSearchBar(searchText: $searchText, isSearching: $isSearching, isShowing: isShowing)
                    }
            } else {
                content
                    .overlay(alignment: .top) {
                        NavigationSearchBar(searchText: $searchText, isSearching: $isSearching, isShowing: isShowing)
                    }
            }
        }
    }
}



