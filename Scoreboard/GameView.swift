//
//  GameView.swift
//  Scoreboard
//
//  Created by user926153 on 8/21/20.
//  Copyright © 2020 user926153. All rights reserved.
//
//
//

/*
 This uses the TrackableScrollView as created by Max Natchanon here:
https://medium.com/@maxnatchanon/swiftui-how-to-get-content-offset-from-scrollview-5ce1f84603ec
 */

import SwiftUI
import UIKit

struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = [CGFloat]
    
    static var defaultValue: [CGFloat] = [0]
    
    static func reduce(value: inout [CGFloat], nextValue: () -> [CGFloat]) {
        value.append(contentsOf: nextValue())
    }
}

struct TrackableScrollView<Content>: View where Content: View {
    let axes: Axis.Set
    let showIndicators: Bool
    @Binding var contentOffset: CGFloat
    let content: Content
    
    init(axis: Axis.Set, showIndicators: Bool = true, contentOffset: Binding<CGFloat>,@ViewBuilder content: () -> Content) {
        self.axes = axis
        self.showIndicators = showIndicators
        self._contentOffset = contentOffset
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { outsideProxy in
            ScrollView(self.axes, showsIndicators: self.showIndicators) {
                ZStack(alignment: self.axes == .vertical ? .top : .leading) {
                    GeometryReader { insideProxy in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: [self.calculateContentOffset(outsideProxy: outsideProxy, insideProxy: insideProxy)])
                            // Send value to the parent
                    }
                    VStack {
                        self.content
                    }
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                self.contentOffset = value[0]
            }
        }
    }
    
    private func calculateContentOffset(outsideProxy: GeometryProxy, insideProxy: GeometryProxy) -> CGFloat {
        if axes == .horizontal {
            let inside = insideProxy.frame(in: .global).minX
            let outside = outsideProxy.frame(in: .global).minX
            return inside - outside
        } else {
            let inside = insideProxy.frame(in: .global).minY
            let outside = outsideProxy.frame(in: .global).minY
            return inside - outside
        }
    }
}


struct GameView: View {
    // core data
    @Environment(\.managedObjectContext) var managed_object_context
    
    // for custom nav button
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var root_view: Bool
    
    let row_label_width: CGFloat = 80
    let col_label_height: CGFloat = 70
    let col_width: CGFloat = 82
    let row_height: CGFloat = 55
    let min_single_round_score: Int = -99999
    let max_single_round_score: Int = 99999
    let min_total_score: Int = -999999
    let max_total_score: Int = 999999
    
    @ObservedObject var game_state: GameStateActive
    @State var column_offset: CGFloat = 0
    @State var row_offset: CGFloat = 0
    @State var selected_round = -1
    @State var selected_player = -1
    @State var new_score: String = ""
    @State var rounds_id = UUID()
    @State var game_over: Bool = false
    @State var winners: [String] = []
    @State var save_failed: Bool = false
    
    init(game_state: GameStateActive, root_view: Binding<Bool>) {
        self._root_view = root_view
        self.game_state = game_state
    }
    
    private func AddRound() {
        if self.game_state.players.count > 0 {
            var new_round: [Int] = []
            for _ in (0...self.game_state.players.count - 1) {
                new_round.append(0)
            }
            
            self.game_state.scores.append(new_round)
            self.rounds_id = UUID()
        }
        
    }
    
    
    private func DeleteRound(round: Int) {
        let round_index = round - 1
        for player_index in (0...self.game_state.players.count - 1) {
            self.game_state.totals[player_index] -= self.game_state.scores[round_index][player_index]
        }
        self.game_state.scores.remove(at: round_index)
    }
    
    private func UpdateScore() {
        if self.new_score.count > 0 {
            let current_score = self.game_state.scores[self.selected_round][self.selected_player]
            
            var new_score = Int(self.new_score)
            
            if new_score != nil {
                // enforce min/max single round score
                if new_score! > self.max_single_round_score {
                    new_score = self.max_single_round_score
                }
                if new_score! < self.min_single_round_score {
                    new_score = self.min_single_round_score
                }
                
                self.game_state.totals[self.selected_player] -= current_score
                
                self.game_state.scores[self.selected_round][self.selected_player] = new_score!
                
                self.game_state.totals[self.selected_player] += new_score!
                
                // enforce min/max total score
                if self.game_state.totals[self.selected_player] > self.max_total_score {
                    self.game_state.totals[self.selected_player] = self.max_total_score
                }
                if self.game_state.totals[self.selected_player] < self.min_total_score {
                    self.game_state.totals[self.selected_player] = self.min_total_score
                }
            }
            else {
                self.new_score = ""
            }
        }
        
        self.new_score = ""
    }
    
    private func EndEditing() {
        self.selected_round = -1
        self.selected_player = -1
        self.new_score = ""
    }
    
    private func NextPhase(player: Int) {
        if self.game_state.phases[player] < 11 {
            self.game_state.phases[player] += 1
        }
    }
    
    private func PreviousPhase(player: Int) {
        if self.game_state.phases[player] > 1 {
            self.game_state.phases[player] -= 1
        }
    }
    
    private func FindWinners() {
        self.winners = []
        
        // find all phase 10ers
        var phase_10ers: [Int] = []
        if self.game_state.phase_10 {
            for player_index in (0...self.game_state.players.count - 1) {
                if self.game_state.phases[player_index] == 11 {
                    phase_10ers.append(player_index)
                }
            }
        }
        
        if phase_10ers.isEmpty {
            var winning_score = self.game_state.totals[0]
            
            // find winning score high or low
            if self.game_state.high_score_wins || self.game_state.phase_10 {
                for player_index in (0...self.game_state.players.count - 1) {
                    if self.game_state.totals[player_index] > winning_score {
                        winning_score = self.game_state.totals[player_index]
                    }
                }
            }
            else {
                for player_index in (0...self.game_state.players.count - 1) {
                    if self.game_state.totals[player_index] < winning_score {
                        winning_score = self.game_state.totals[player_index]
                    }
                }
            }
            
            // find all winners
            for player_index in (0...self.game_state.players.count - 1) {
                if self.game_state.totals[player_index] == winning_score {
                    self.winners.append(self.game_state.players[player_index])
                }
            }
        }
        else {
            var winning_score = self.game_state.totals[phase_10ers[0]]
            
            // find high score among phase 10ers
            for player in phase_10ers {
                if self.game_state.totals[player] > winning_score {
                    winning_score = self.game_state.totals[player]
                }
            }
            
            // find all winners
            for player in phase_10ers {
                if self.game_state.totals[player] == winning_score {
                    self.winners.append(self.game_state.players[player])
                }
            }
        }
    }
    
    private func SaveGame() {
        let save_game = self.game_state.loaded_game != nil ? self.game_state.loaded_game : GameStateSaved(context: self.managed_object_context)
        
        save_game?.game_name        =   self.game_state.game_name
        save_game?.high_score_wins  =   self.game_state.high_score_wins
        save_game?.phase_10         =   self.game_state.phase_10
        save_game?.players          =   self.game_state.players
        save_game?.phases           =   self.game_state.phases
        save_game?.totals           =   self.game_state.totals
        save_game?.scores           =   self.game_state.scores
        save_game?.end_date         =   Date()
        
        do {
            try self.managed_object_context.save()
        }
        catch {
            self.save_failed = true
        }
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // NAV BAR
            HStack {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text("edit")
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                self.hideKeyboard()
                self.EndEditing()
            }
            
            // GAME NAME
            VStack(alignment: .center, spacing: 5) {
                Text(self.game_state.game_name)
                    .font(.title)
                
                if self.game_state.high_score_wins {
                    Text("high score wins")
                }
                else {
                    Text("low score wins")
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                self.hideKeyboard()
                self.EndEditing()
            }
            
            // EDITING
            HStack(alignment: .center, spacing: 0) {
                if self.selected_round > -1 &&
                   self.selected_player > -1 &&
                   self.selected_player < self.game_state.players.count &&
                   self.selected_round < self.game_state.scores.count {
                    
                    Text("Round \(self.selected_round + 1)")
                    .fontWeight(.bold)
                    .frame(minWidth: self.row_label_width, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // DUMMY GESTURE
                        let r = self.selected_round
                        let p = self.selected_player
                        self.selected_round = r
                        self.selected_player = p
                    }
                    
                    Text(self.game_state.players[self.selected_player])
                    .fontWeight(.bold)
                    .frame(minWidth: self.col_width, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // DUMMY GESTURE
                        let r = self.selected_round
                        let p = self.selected_player
                        self.selected_round = r
                        self.selected_player = p
                    }
                    
                    TextField("New score", text: $new_score, onCommit: {
                        self.UpdateScore()
                        self.EndEditing()
                    })
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                    
                    Button(action: {
                        self.UpdateScore()
                    }) {
                        Text("Submit")
                            .fontWeight(.bold)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                }
                else {
                    Text("")
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // DUMMY GESTURE
                        let r = self.selected_round
                        let p = self.selected_player
                        self.selected_round = r
                        self.selected_player = p
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, maxHeight: 50)
            .padding([.leading, .trailing], 15)
            
            VStack(alignment: .center, spacing: 0) {
                // COLUMNS
                HStack(spacing:0) {
                    // ADD NEW ROUND
                    Button(action: {
                        self.AddRound()
                    }) {
                        Text("New round +")
                        .fixedSize(horizontal: false, vertical: true)
                        
                    }
                    .frame(width: self.row_label_width, height: self.col_label_height)
                    .border(Color.primary)
                    
                    // PLAYER COLS
                    TrackableScrollView(axis: .horizontal, showIndicators: true, contentOffset: $column_offset) {
                        HStack(spacing: 0) {
                            if self.game_state.players.count > 0 {
                                ForEach((0...self.game_state.players.count - 1), id: \.self) { player_index in
                                    VStack(spacing: 1) {
                                        Text(self.game_state.players[player_index])
                                        
                                        Text("\(self.game_state.totals[player_index])")
                                        
                                        if self.game_state.phase_10 {
                                            if self.game_state.phases[player_index] < 11 {
                                                Text("\(self.game_state.phases[player_index])")
                                                    .fontWeight(.bold)
                                                    .italic()
                                            }
                                            else {
                                                Text("Finished!")
                                                    .foregroundColor(.green)
                                                    .fontWeight(.bold)
                                                    .italic()
                                            }
                                        }
                                    }
                                    .frame(width: self.col_width, height: self.col_label_height)
                                    .border(Color.primary)
                                    .contextMenu {
                                        if self.game_state.phase_10 {
                                            Button(action: {
                                                self.NextPhase(player: player_index)
                                            }) {
                                                Text("Next Phase")
                                            }
                                            
                                            Button(action: {
                                                self.PreviousPhase(player: player_index)
                                            }) {
                                                Text("Previous Phase")
                                            }
                                        }
                                        else {
                                            Text("Nothing to see here!")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(height: self.col_label_height)
                
                // ROUNDS + MAIN GRID
                HStack(spacing: 0) {
                    TrackableScrollView(axis: .vertical, showIndicators: true, contentOffset: $row_offset) {
                        ForEach((1...self.game_state.scores.count).reversed(), id: \.self) { round in
                            Text("Round \(round)")
                            .frame(width:self.row_label_width, height: self.row_height)
                            .contextMenu {
                                Button(action: {
                                    if self.game_state.scores.count > 1 {
                                        self.DeleteRound(round: round)
                                    }
                                }) {
                                    if self.game_state.scores.count > 1 {
                                        Text("Delete")
                                        Image(systemName: "trash")
                                    }
                                    else {
                                        Text("Can't delete the only round!")
                                    }
                                }
                            }
                        }
                        .border(Color.primary)
                    }
                    .frame(width: self.row_label_width)
                    .id(self.rounds_id)
                    
                    // MAIN GRID
                    Color.clear.overlay(
                        HStack(alignment: .top, spacing: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(self.game_state.scores.indices.reversed(), id: \.self) { round_index in
                                    HStack(spacing: 0) {
                                        ForEach(self.game_state.scores[0].indices, id: \.self) { player_index in
                                            Text("\(self.game_state.scores[round_index][player_index])")
                                            .frame(width: self.col_width, height: self.row_height)
                                            .foregroundColor(self.selected_round == round_index &&
                                                    self.selected_player == player_index ?
                                                        Color.yellow : Color.primary)
                                            .border(self.selected_round == round_index &&
                                                    self.selected_player == player_index ?
                                                    Color.yellow : Color.primary)
                                            .onTapGesture {
                                                self.selected_round = round_index
                                                self.selected_player = player_index
                                            }
                                                
                                        }
                                    }
                                    .frame(height: self.row_height)
                                }
                                
                                // Empty view in order to tap to hide keyboard
                                HStack {
                                    EmptyView()
                                }
                                .frame(minWidth: self.col_width * CGFloat(self.game_state.players.count), maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    self.hideKeyboard()
                                    self.EndEditing()
                                }
                            }
                            
                            // Empty view in order to tap to hide keyboard
                            VStack {
                                EmptyView()
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.hideKeyboard()
                                self.EndEditing()
                            }
                            
                        }
                        .offset(x: self.column_offset, y: self.row_offset)
                        , alignment: .topLeading
                    )
                    .clipped()
                }
            }
            .padding([.leading, .trailing], 15)
            
            Button(action: {
                self.FindWinners()
                self.SaveGame()
                self.game_over = true
            }) {
                Text("End Game")
                    .font(.title)
            }
            .frame(height: 70)
            
            NavigationLink(destination: CongratulationsView(root_view: self.$root_view, winners: self.winners, save_failed: self.save_failed), isActive: $game_over) {
                EmptyView()
            }
            .isDetailLink(false)
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

#if DEBUG

struct GameView_Previews: PreviewProvider {
    
    static var previews: some View {
        GameView(game_state: GameStateActive(), root_view: .constant(true))
    }
}
#endif

