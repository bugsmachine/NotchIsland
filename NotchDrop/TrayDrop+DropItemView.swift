//
//  TrayDrop+DropItemView.swift
//  NotchIsland
//
//  Created by 曹丁杰 on 2024/8/10.
//

import Foundation
import Pow
import SwiftUI
import UniformTypeIdentifiers

struct DropItemView: View {
    @ObservedObject var item: TrayDrop.DropItem
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared

    @State var hover = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Image(nsImage: item.workspacePreviewImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 64)
                
            
            Text(item.fileName)
                .multilineTextAlignment(.center)
                .font(.system(.footnote, design: .rounded))
                .frame(maxWidth: 64)
                .lineLimit(1)
                .truncationMode(.tail)
                
            
            switch item.state {
            case .idle:
                Image(systemName: "icloud")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: 10)
            case .uploading:
                Image(systemName: "icloud.and.arrow.down.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: 10)
            case .uploaded:
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.green)
                    .frame(maxWidth: 10)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.red)
                    .frame(maxWidth: 10)
            case .notInLocal:
                Image(systemName: "icloud.and.arrow.down.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: 10)
            case .notInCloud:
                Image(systemName: "icloud.and.arrow.up.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.yellow)
                    .frame(maxWidth: 10)
            }
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale),
            removal: .movingParts.poof
        ))
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .scaleEffect(hover ? 1.05 : 1.0)
        .animation(vm.animation, value: hover)
        .onDrag { NSItemProvider(contentsOf: item.storageURL) ?? .init() }
        .onTapGesture {
            guard !vm.optionKeyPressed else { return }
            vm.notchClose()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSWorkspace.shared.open(item.storageURL)
            }
        }
        .overlay {
            Image(systemName: "xmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.red)
                .background(Color.white.clipShape(Circle()).padding(1))
                .frame(width: vm.spacing, height: vm.spacing)
                .opacity(vm.optionKeyPressed ? 1 : 0)
                .scaleEffect(vm.optionKeyPressed ? 1 : 0.5)
                .animation(vm.animation, value: vm.optionKeyPressed)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .offset(x: vm.spacing / 2, y: -vm.spacing / 2)
                .onTapGesture { tvm.delete(item.id) }
        }
    }
}
