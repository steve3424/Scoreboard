//
//  ContentView.swift
//  Scoreboard
//
//  Created by Steve F. on 8/19/20.
//  Copyright © 2020 Steve F. All rights reserved.
//

import SwiftUI


struct ContentView: View {
    @State var new_game_nav: Bool = false
    @State var previous_games_nav: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 10) {
                Text("Scoreboard")
                    .font(.system(size: 50))
                
                Button(action: {
                    self.new_game_nav = true
                }) {
                    Text("New Game")
                       .font(.system(size: 25))
                }
                
                Button(action: {
                    self.previous_games_nav = true
                }) {
                    Text("Previous Games")
                       .font(.system(size: 25))
                }
                
                NavigationLink(destination: CreateGameView(root_view: self.$new_game_nav), isActive: $new_game_nav) {
                    EmptyView()
                }
                .isDetailLink(false)
                
                NavigationLink(destination: PreviousGamesView(root_view: self.$previous_games_nav), isActive: $previous_games_nav) {
                    EmptyView()
                }
                .isDetailLink(false)
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
