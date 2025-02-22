//
//  QAListView.swift
//  ChatShare
//
//  Created by 孟超 on 2025/2/7.
//

import SwiftUI
import Localization

struct QAListView: QANavigationRoot {
    
    typealias Target = QAInputView
    
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @Environment(QANavigationModel.self) var navigationModel: QANavigationModel
    @Environment(QADataManager.self) var dataManager: QADataManager
    
    @Environment(\.editMode) var editMode: Binding<EditMode>?
    
    var isEditing: Bool { editMode?.wrappedValue.isEditing == true }
    
    var content: some View {
        QAListDateView()
            .environment(viewModel)
            .environment(navigationModel)
            .environment(dataManager)
            .listStyle(.sidebar)
            .toolbar(content: self.toolbar)
            .searchable(text: viewModel.binding(for: \.listSearchText), isPresented: viewModel.binding(for: \.isListSearching), placement: .navigationBarDrawer(displayMode: .always), prompt: nil)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: { viewModel.listSelectedModels = .init() })
    }
}

extension QAListView {
    
    var topMenu: some View {
        Menu(systemImage: "ellipsis.circle") {
            Picker(selection: viewModel.binding(for: \.listSort)) {
                ForEach(QADataManager.Sort.allCases) { sort in
                    Text(sort.title).tag(sort)
                }
                Divider()
            } label: {
                Label("Sorted By", systemImage: "arrow.up.arrow.down")
                Text(viewModel.listSort.title)
            }
            .pickerStyle(.menu)
            Picker(selection: viewModel.binding(for: \.listSordOrder)) {
                ForEach(SortOrder.allCases) { value in
                    Text(viewModel.listSort.orderTitle(value)).tag(value)
                }
            } label: {
                Label("Ordered By", systemImage: "arrow.trianglehead.swap")
                Text(viewModel.listSort.orderTitle(viewModel.listSordOrder))
            }
            .pickerStyle(.menu)
            Divider()
            EditButton()
                .labelStyle(Text("Select Items"), systemImage: "checkmark.circle")
        }
    }
    
    @ToolbarContentBuilder
    func toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            topMenu.withCondition { view in
                if editMode?.wrappedValue.isEditing == true {
                    EditButton()
                } else { view }
            }
        }
        ToolbarItem(placement: .bottomBar) {
            HStack(alignment: .center, spacing: 0.0) {
                Text("\(dataManager.allModels.count) Items")
                    .withCondition(body: { view in
                        let searchResult = viewModel.listSearchingResult
                        if !searchResult.isEmpty && !viewModel.listSearchText.isEmpty {
                            Text("\(searchResult.count) Found")
                        } else if viewModel.listSearchText.isEmpty { view }
                    })
                    .font(.footnote)
                    .frame(alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .trailing) {
                QANavigationLink(Target.self, onCompletion: viewModel.prepareNewQAContent) {
                    Image(systemName: "square.and.pencil")
                }
                .hidden(viewModel.isListSearching || isEditing)
            }
            .overlay(alignment: .leading) {
                Button {
                    viewModel.listSelectedModels.forEach { model in
                        dataManager.remove(id: model.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .bold()
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.listSelectedModels.isEmpty)
                .hidden(!isEditing)
            }
        }
    }
}



//MARK: - List Content Sorted by Content

fileprivate struct QAListDateView: View {
    typealias Target = QAListView.Target
    
    @Environment(QAViewModel.self) var viewModel: QAViewModel
    @Environment(QANavigationModel.self) var navigationModel: QANavigationModel
    @Environment(QADataManager.self) var dataManager: QADataManager
    
    @Environment(\.editMode) var editMode: Binding<EditMode>?
    
    var body: some View {
        Group {
            switch viewModel.listSort {
                case .title:
                    titleSortContent
                case .date(let dateSort):
                    dateSortContent(dateSortType: dateSort)
            }
        }
        .background(Color.listBackgroundColor, ignoresSafeAreaEdges: .all)
        .scrollContentBackground(.hidden)
    }
    
    @ViewBuilder
    var titleSortContent: some View {
        let models = dataManager
            .models(sort: .title, order: viewModel.listSordOrder)
            .filter(prompt: viewModel.listSearchText)
        List(selection: viewModel.binding(for: \.listSelectedModels)) {
            ForEach(models, id: \.id) { model in
                QANavigationLink(Target.self) {
                    viewModel.prepareForQAModel(model)
                } label: {
                    label(model: model)
                }
                .tag(model)
            }
        }
        .withCondition { view in
            if models.isEmpty && viewModel.isListSearching {
                searchingPlaceHolder
            } else { view }
        }
    }
    
    @ViewBuilder
    func dateSortContent(dateSortType: QADataManager.DateSort) -> some View {
        let dateTypes = dataManager.dateTypes(sort: dateSortType, order: viewModel.listSordOrder, filterPrompt: viewModel.listSearchText)
        List(selection: viewModel.binding(for: \.listSelectedModels)) {
            ForEach(dateTypes) { dateType in
                Section(content: {
                    let models = dataManager
                        .models(sort: dateSortType, dateType: dateType, order: viewModel.listSordOrder)
                        .filter(prompt: viewModel.listSearchText)
                    ForEach(models, id: \.id) { model in
                        QANavigationLink(Target.self) {
                            viewModel.prepareForQAModel(model)
                        } label: {
                            label(model: model)
                        }
                        .tag(model)
                    }
                }, header: {
                    Text(dateType.title)
                        .textCase(.none)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.dynamicBlack)
                        .listRowInsets(.init())
                        .padding(.vertical, 8.0)
                        .padding(.leading, length: 2.0)
                })
            }
        }
        .withCondition { view in
            if dateTypes.isEmpty && viewModel.isListSearching {
                searchingPlaceHolder
            } else { view }
        }

    }
    
    var searchingPlaceHolder: some View {
        ContentUnavailableView("No results for \"\(viewModel.listSearchText)\"", systemImage: "magnifyingglass", description: Text("Please Check spelling or input a new search text."))
            .listRowBackground(Color.clear)
            .listRowInsets(.init())
            .listRowSpacing(0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color.listBackgroundColor, ignoresSafeAreaEdges: .all)
    }
    
    @ViewBuilder
    func label(model: QADataModel) -> some View {
        let trimQuestion = model.question
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let questionTitle = trimQuestion.isEmpty ? #localized("Untitled") : trimQuestion
        let answerResult = model.answer
            .trimmingCharacters(in: .whitespacesAndNewlines)
        VStack(alignment: .leading) {
            Text(questionTitle)
                .lineLimit(1, reservesSpace: true)
                .fontWeight(.medium)
            HStack {
                Text(model.createDate.formatted())
                Text(LocalizedStringKey(answerResult))
                    .lineLimit(1, reservesSpace: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.secondary)
            .font(.footnote)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                dataManager.remove(id: model.id)
            } label: {
                Image(systemName: "trash")
            }
        }
    }
}
