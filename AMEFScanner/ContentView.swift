import SwiftUI


enum ScanStatus {
    case scanning
    case success
    case failure
    case nodata
}

struct ContentView: View {
    @State private var showScannerSheet = false
    @State private var status: ScanStatus = .scanning
    @State private var SerieFiscala: String = ""
    var body: some View {
        if(status == .scanning){
            NavigationView{
                VStack{
                    
                    Text("Te rugam sa scanezi cat mai vizibil bonul fiscal")
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        self.showScannerSheet = true
                    }, label: {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title)
                    })
                }
                
                    .navigationTitle("Scanare")
                    .navigationBarItems(trailing: Button(action: {
                        self.showScannerSheet = true
                    }, label: {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title)
                    })
                    .sheet(isPresented: $showScannerSheet, content: {
                        self.makeScannerView()
                    })
                    )
            }
        }
        else if (status == .success) {
            NavigationView{
                ZStack {
                    Color.green
                        .ignoresSafeArea()
                    VStack{
                        
                        Text("Casa de marcat \n \(self.SerieFiscala) \n ESTE \n conectata la ANAF")
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        
                        Button(action: {
                            self.showScannerSheet = true
                        }, label: {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title)
                        })
                        
                    }
                }
                
                    .navigationTitle("Success")
                    .navigationBarItems(trailing: Button(action: {
                        self.showScannerSheet = true
                    }, label: {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title)
                    })
                    .sheet(isPresented: $showScannerSheet, content: {
                        self.makeScannerView()
                    })
                    )
                
            }
        }
        else if (status == .failure) {
            NavigationView{
                ZStack{
                    Color.red
                        .ignoresSafeArea()
                    VStack{
                        Text("Casa de marcat \n \(self.SerieFiscala) \n NU este \n conectata la ANAF")
                            .font(.title)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        
                        Button(action: {
                            self.showScannerSheet = true
                        }, label: {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title)
                        })
                    }
                    
                }
                
                
                    .navigationTitle("Alerta")
                    .navigationBarItems(trailing: Button(action: {
                        self.showScannerSheet = true
                    }, label: {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title)
                    })
                    .sheet(isPresented: $showScannerSheet, content: {
                        self.makeScannerView()
                    })
                    )
            }
        }
        else if(status == .nodata){
            NavigationView{
                ZStack {
                    Color.yellow
                        .ignoresSafeArea()
                    VStack{
                        Text("Te rugam sa repeti scanarea")
                            .font(.title)
                            .multilineTextAlignment(.center)
                        
                        
                        Button(action: {
                            self.showScannerSheet = true
                        }, label: {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.title)
                        })
                    }
                }
                
                    .navigationTitle("Scanare")
                    .navigationBarItems(trailing: Button(action: {
                        self.showScannerSheet = true
                    }, label: {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.title)
                    })
                    .sheet(isPresented: $showScannerSheet, content: {
                        self.makeScannerView()
                    })
                    )
            }
        }
        
    }
    private func makeScannerView()-> ScannerView {
        ScannerView(completion: {
            textPerPage in
            if let outputText = textPerPage?.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines){
                let newScanData = ScanData(content: outputText)
                if (newScanData.content == ""){
                    self.status = .nodata
                }
                else {
                    self.status = .failure
                    self.SerieFiscala = newScanData.content
                }
            }
            self.showScannerSheet = false
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
