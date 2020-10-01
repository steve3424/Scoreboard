//
//  PreviousGamesView.swift
//  Scoreboard
//
//  Created by user179118 on 9/9/20.
//  Copyright © 2020 stevef. All rights reserved.
//

import SwiftUI

struct PreviousGamesView: View {
    // core data
    @Environment(\.managedObjectContext) var managed_object_context
    @FetchRequest(fetchRequest: GameStateSaved.GetGames()) var games:FetchedResults<GameStateSaved>
    
    // custom navigation
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var root_view: Bool
    
    @State var load_game_nav: Bool = false
    @State var game_to_load: GameStateSaved? = nil
    @State var save_failed: Bool = false
    
    var date_formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    init(root_view: Binding<Bool>) {
        self._root_view = root_view
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // NAV BAR
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text("back")
                    }
                }
                
                Spacer()
            }
            .padding()
            
            List {
                ForEach(self.games) { game in
                    HStack(alignment: .bottom, spacing: 10) {
                        Text(game.game_name)
                        Spacer()
                        Text(self.date_formatter.string(from: game.end_date))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: {
                        self.game_to_load = game
                        self.load_game_nav = true
                    })
                }
                .onDelete(perform: { index_set in
                    let delete_item = self.games[index_set.first!]
                    self.managed_object_context.delete(delete_item)
                    
                    do {
                        try self.managed_object_context.save()
                    }
                    catch {
                        self.save_failed = true
                    }
                })
            }
            .alert(isPresented: $save_failed) {
                Alert(title: Text("Save Game Failed!"), message: Text("Something went wrong and this game did not save. Sorry."), dismissButton: .default(Text("OK")))
            }
            
            NavigationLink(destination: CreateGameView(game_to_load: self.game_to_load, root_view: self.$load_game_nav), isActive: $load_game_nav) {
                EmptyView()
            }
            .isDetailLink(false)
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

struct PreviousGamesView_Previews: PreviewProvider {
    static var previews: some View {
        PreviousGamesView(root_view: .constant(true))
    }
}
