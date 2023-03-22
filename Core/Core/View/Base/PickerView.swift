//
//  PickerView.swift
//  Core
//
//  Created by  Stepanok Ivan on 26.10.2022.
//

import SwiftUI

public struct PickerView: View {
    
    @ObservedObject
    private var config: FieldConfiguration
    private var router: BaseRouter
    
    public init(config: FieldConfiguration, router: BaseRouter) {
        self.config = config
        self.router = router
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            Group {
                Text(config.field.label)
                    .font(Theme.Fonts.labelLarge)
                    .foregroundColor(CoreAssets.textPrimary.swiftUIColor)
                    .padding(.top, 18)
                HStack {
                    Button(action: {
                        withAnimation(
                            Animation.easeInOut(duration: 0.3)
                        ) {
                            let pickerItems = config.field.options.map { PickerItem(key: $0.value, value: $0.name) }
                            router.presentView(transitionStyle: .crossDissolve) {
                                PickerMenu(items: pickerItems,
                                           titleText: config.field.label,
                                           router: router,
                                           selectedItem: config.selectedItem,
                                           selected: { item in
                                    config.selectedItem = item
                                    config.text = item.key
                                })
                            }
                        }
                    }, label: {
                        Text(config.selectedItem?.value ?? "")
                        Spacer()
                        Image(systemName: "chevron.down")
                    })
                }.padding(.all, 14)
                    .foregroundColor(CoreAssets.textPrimary.swiftUIColor)
                    .background(
                        Theme.Shapes.textInputShape
                            .fill(CoreAssets.textInputBackground.swiftUIColor)
                    )
                    .overlay(
                        Theme.Shapes.textInputShape
                            .stroke(lineWidth: 1)
                            .fill(config.error == "" ?
                                  CoreAssets.textInputStroke.swiftUIColor
                                  : Color.red)
                    )
                    .shake($config.shake)
                Text(config.error == "" ? config.field.instructions
                     : config.error)
                .font(Theme.Fonts.labelMedium)
                .foregroundColor(config.error == ""
                                 ? CoreAssets.textPrimary.swiftUIColor
                                 : Color.red)
            }
        }
    }
}

#if DEBUG
struct PickerView_Previews: PreviewProvider {
    static var previews: some View {
        let registrationFields = PickerFields(
            type: .select,
            label: "Select Country",
            required: true,
            name: "Country",
            instructions: "Choose your country",
            options: [
                PickerFields.Option(
                    value: "UA",
                    name: "Ukraine", optionDefault: true)
            ]
        )
        return PickerView(
            config: FieldConfiguration(text: "asd", field: registrationFields),
            router: BaseRouterMock()
        )
        .padding()
    }
}
#endif