//
//  ContentView.swift
//  LittleGalileo
//
//  Created by 钱前 on 2026/7/4.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TonightView()
                .tabItem {
                    Label("今晚", systemImage: "moon.stars.fill")
                }

            SkyMapView()
                .tabItem {
                    Label("星图", systemImage: "star.circle.fill")
                }

            CardListView()
                .tabItem {
                    Label("图鉴", systemImage: "book.fill")
                }

            CollectionView()
                .tabItem {
                    Label("收藏", systemImage: "trophy.fill")
                }
        }
        .tint(Color(hex: "FFD700"))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(StarCatalog())
        .environmentObject(LocationManager())
        .environmentObject(CollectionStore())
}
