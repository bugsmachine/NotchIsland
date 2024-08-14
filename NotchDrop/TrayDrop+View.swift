import SwiftUI

struct TrayView: View {
    @StateObject var vm: NotchViewModel
    @StateObject var tvm = TrayDrop.shared

    @State private var targeting = false
    @State private var isLoading = true  // State to indicate loading status

    private func checkFileStates() {
        let user = UserDefaults.standard.string(forKey: "userID") ?? ""
        let dispatchGroup = DispatchGroup()
        
        // Start loading
        isLoading = true

        // Check file state for each item
        for item in tvm.items {
            dispatchGroup.enter()
            checkIfFileOnCloud(fileName: item.fileName, user: user) { isOnCloud in
                DispatchQueue.main.async {
                    item.state = isOnCloud ? .uploaded : .notInCloud
                    dispatchGroup.leave()
                }
            }
        }

        // Notify when all checks are done
        dispatchGroup.notify(queue: .main) {
            isLoading = false
        }
    }

    var storageTime: String {
        switch vm.selectedFileStorageTime {
        case .oneDay:
            return NSLocalizedString("a day", comment: "")
        case .twoDays:
            return NSLocalizedString("two days", comment: "")
        case .threeDays:
            return NSLocalizedString("three days", comment: "")
        case .oneWeek:
            return NSLocalizedString("a week", comment: "")
        case .never:
            return NSLocalizedString("forever", comment: "")
        case .custom:
            let localizedTimeUnit = NSLocalizedString(vm.customStorageTimeUnit.localized.lowercased(), comment: "")
            return "\(vm.customStorageTime) \(localizedTimeUnit)"
        }
    }

    var body: some View {
        panel
            .onDrop(of: [.data], isTargeted: $targeting) { providers in
                DispatchQueue.global().async {
                    tvm.load(providers)
                    print("Dropped new item")
                }
                return true
            }
            .onAppear {
                checkFileStates()
            }
    }

    var panel: some View {
        RoundedRectangle(cornerRadius: vm.cornerRadius)
            .strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [10]))
            .foregroundStyle(.white.opacity(0.1))
            .background(loading)
            .overlay {
                content
                    .padding()
            }
            .animation(vm.animation, value: tvm.items)
            .animation(vm.animation, value: tvm.isLoading)
    }

    var loading: some View {
        RoundedRectangle(cornerRadius: vm.cornerRadius)
            .foregroundStyle(.white.opacity(0.1))
            .conditionalEffect(
                .repeat(
                    .glow(color: .blue, radius: 50),
                    every: 1.5
                ),
                condition: tvm.isLoading > 0
            )
    }

    var content: some View {
        Group {
            if isLoading {
                // Show loading indicator or placeholder
                VStack {
                    ProgressView("Loading...")
                    Text("Fetching file states...")
                        .font(.system(.headline, design: .rounded))
                }
            } else if tvm.isEmpty {
                VStack {
                    Image(systemName: "tray.and.arrow.down.fill")
                    Text(NSLocalizedString("Drag files here to keep them for", comment: "") + " " + storageTime + " " + NSLocalizedString("& Press Option to delete", comment: ""))
                        .font(.system(.headline, design: .rounded))
                }
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: vm.spacing) {
                        ForEach(tvm.items) { item in
                            DropItemView(item: item, vm: vm, tvm: tvm)
                        }
                    }
                    .padding(.bottom,-10)
                    .padding(vm.spacing)
                }
                .padding(-vm.spacing)
                .scrollIndicators(.never)
            }
        }
    }
}

#Preview {
    NotchContentView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center)
        .background(.black)
        .preferredColorScheme(.dark)
}
