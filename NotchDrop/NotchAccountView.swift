import SwiftUI


struct NotchAccountView: View {
    @StateObject var vm: NotchViewModel
    
    @State private var userEmail: String = UserDefaults.standard.string(forKey: "userEmail") ?? "nil"
    
    @State private var userSubscription: String = UserDefaults.standard.string(forKey: "userSubscription") ?? "nil"
    @State var space1x = 0.0
    @State var space1y = 0.0
    
    @State var space2x = 0.0
    @State var space2y = 0.0
    
    @State var space3x = 0.0
    @State var space3y = 0.0
    
    @State var space4x = 0.0
    @State var space4y = 0.0

    

    var body: some View {
        
        VStack {
        
            VStack {
                // Conditional Views
                if vm.loginStatus == .login {
                    VStack {
                                            // First Line
                        VStack {
                            // HStack for "Account" and "userEmail"
                            HStack {
                                Text("Account: ")
                                    .frame(maxWidth: .infinity, alignment: .leading)  // Align to leading edge of HStack
                                    
                                    .position(x: space1x, y: space1y)
                                
                                Text(userEmail)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: 240, alignment: .leading)
                                    .position(CGPoint(x: space2x, y:space2y))//-93,3
                            }
                            

                        
                            HStack {
                                Text("Subscription: ")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .position(x: space3x, y: space3y)
                                Text(userSubscription)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .position(CGPoint(x: space4x, y:space4y))
                            }
                            .frame(width: 250) // Set the width as per your requirement
                            .position(x: 380, y: -10) // Set the position as per your requirement
                        }.padding(.top,-15)
                                            

                                            // Second Line
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text("Storage Usage: 45MB / 500MB")
                                                    
                                                    ProgressBar(value: 0.45) // Example progress bar value
                                                        .frame(height: 10)
                                                }
                                                Rectangle()
                                                    .frame(width: 290) // Adjust width as needed
                                                    .opacity(0)
                                            }
                                            
                                            // Logout Button aligned with Subscription
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    vm.logoutUser()
                                                    // Handle logout action
                                                }) {
                                                    Text("Logout")
                                                        .foregroundColor(.red)
                                                        .frame(alignment: .leading)
                                                        
                                                }.position(x: 200, y: 10)
                                                .transition(.scale(scale: 0.8).combined(with: .opacity))
                                            }
                                            .padding(.horizontal,154)
                                            .padding(.top,-36)
                                        }
                                        
                } else {
                    VStack {
                        Text("You are not logged in")
                            .padding(.top,-30)
                            .padding(.bottom,-10)
                        
                        Button(action: {
                            // Open login page
                            NSWorkspace.shared.open(loginPage)
                            vm.notchClose()
                        }) {
                            Text("Login or Register")
                        }
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                    .padding()
                }
            }
            .padding()
        }.onAppear {
            updateSpaceValues()
        }
    }
    
    private func updateSpaceValues() {
            let code = vm.getLanguageCode()
            if code == "zh-Hans" {
                space1x = 150
                space1y = 4
                space2x = -93
                space2y = 3
                space3x = 135
                space3y = 1
                space4x = 75
                space4y = 0
            } else if code == "zh-Hant" {
                space1x = 150
                space1y = 4
                space2x = -93
                space2y = 3
                space3x = 135
                space3y = 1
                space4x = 75
                space4y = 0
            }else{
                space1x = 150
                space1y = 4
                space2x = -75
                space2y = 4
                space3x = 135
                space3y = 1
                space4x = 90
                space4y = 1
            }
        }
}

struct ProgressBar: View {
    var value: Double
    
    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: 200,height: 5)
                .foregroundColor(Color.gray.opacity(0.3))
            RoundedRectangle(cornerRadius: 5)
                .frame(width: CGFloat(value) * 100, height: 5) // Adjust width if needed
                .foregroundColor(.blue)
        }
    }
}



#Preview {
    NotchAccountView(vm: .init())
        .padding()
        .frame(width: 600, height: 150, alignment: .center) // Adjust height as needed
        .background(Color.black)
        .preferredColorScheme(.dark)
}
