//
//  FlowLayout.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

struct FlowLayout<Data: RandomAccessCollection, ID: Hashable, ItemView: View>: View {
    let data: Data
    let idKeyPath: KeyPath<Data.Element, ID>
    let viewForItem: (Data.Element) -> ItemView
    let spacing: CGFloat

    init(_ data: Data, id: KeyPath<Data.Element, ID>, spacing: CGFloat = 8, @ViewBuilder viewForItem: @escaping (Data.Element) -> ItemView) {
        self.data = data
        self.idKeyPath = id
        self.spacing = spacing
        self.viewForItem = viewForItem
    }

    var body: some View {
        GeometryReader { geometry in
            content(in: geometry)
                .anchorPreference(key: HeightPreferenceKey.self, value: .bounds) { anchor in
                    max(0, geometry[anchor].maxY.isNaN ? 0 : geometry[anchor].maxY)
                }
        }
    }

    private func content(in geometry: GeometryProxy) -> some View {
        var currentX: CGFloat = 0, currentY: CGFloat = 0, rowHeight: CGFloat = 0
        var itemPositions: [ID: CGPoint] = [:]
        let isGeometryValid = geometry.size.width.isFinite && geometry.size.width > 0 && geometry.size.height.isFinite

        if isGeometryValid {
            for item in data {
                let itemID = item[keyPath: idKeyPath]
                let itemView = viewForItem(item)
                let itemSize = itemView.fixedSize().intrinsicContentSize
                guard itemSize.width.isFinite && itemSize.width >= 0 && itemSize.height.isFinite && itemSize.height >= 0 else { continue }
                let safeSpacing = max(0, spacing)
                if currentX + itemSize.width + safeSpacing > geometry.size.width && currentX > 0 {
                    if !rowHeight.isFinite { rowHeight = 0 }
                    currentY += rowHeight + safeSpacing
                    currentX = 0; rowHeight = 0
                }
                guard currentX.isFinite, currentY.isFinite else { continue }
                itemPositions[itemID] = CGPoint(x: currentX, y: currentY)
                currentX += itemSize.width + safeSpacing
                rowHeight = max(rowHeight, itemSize.height)
                guard currentX.isFinite, rowHeight.isFinite else { break }
            }
        }

        return ZStack(alignment: .topLeading) {
            if isGeometryValid {
                ForEach(data, id: idKeyPath) { item in
                    let itemID = item[keyPath: idKeyPath]
                    if let position = itemPositions[itemID], position.x.isFinite, position.y.isFinite {
                        viewForItem(item)
                            .alignmentGuide(.leading) { _ in -position.x }
                            .alignmentGuide(.top) { _ in -position.y }
                    }
                }
            }
        }
    }
}
