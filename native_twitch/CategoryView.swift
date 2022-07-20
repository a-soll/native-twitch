//
//  CategoryView.swift
//  native_twitch
//
//  Created by Adam Solloway on 7/18/22.
//

import SwiftUI

struct CategoryItem: View {
    var title: String
    var url: URL
    @State var animate = false
    
    init(title: String, url: String) {
        self.title = title
        self.url = URL(string: url)!
    }
    
    var body: some View {
        VStack {
            GameImage(url: url).image
                .cornerRadius(12)
            Text(self.title)
        }
        .padding(EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: 1))
        .scaleEffect(x: animate ? 1.1 : 1, y: animate ? 1.1 : 1)
        .animation(.easeIn(duration: 0.1), value: animate)
        .onHover(perform: { hover in
            animate = hover
        })
    }
}

struct CategoryView: View {
    @ObservedObject var landingPage = LandingPage()
    @Binding var gameSelection: Bool
    @Binding var selectedGame: Game?

    var gridItemLayout = [
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0),
        GridItem(.flexible(), spacing: 0)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 30) {
                ForEach(0..<Int(landingPage.items), id: \.self) { i in
                    var game = self.landingPage.games![i]
                    CategoryItem(title: String(cString: &game.name.0), url: String(cString: &game.box_art_url.0))
                        .onAppear(perform: {
                            if i == landingPage.items - 1 {
                                landingPage.fetch()
                            }
                        })
                        .onTapGesture {
                            selectedGame = game
                            gameSelection = true
                        }
                }
            }.padding(EdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 0))
        }
    }
}
