//
//  RegisterViewModelTests.swift
//  AuthorizationTests
//
//  Created by  Stepanok Ivan on 15.01.2023.
//

import SwiftyMocky
import XCTest
@testable import Core
@testable import Authorization
import Alamofire
import SwiftUI

final class SignUpViewModelTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testGetRegistrationFieldsSuccess() async throws {
        let interactor = AuthInteractorProtocolMock()
        let router = AuthorizationRouterMock()
        let validator = Validator()
        let viewModel = SignUpViewModel(interactor: interactor,
                                        router: router,
                                        config: ConfigMock(),
                                        cssInjector: CSSInjectorMock(),
                                        validator: validator)
        
        let fields = [
            PickerFields(type: .email, label: "", required: true, name: "email", instructions: "", options: []),
            PickerFields(type: .password, label: "", required: true, name: "password", instructions: "", options: []),
            PickerFields(type: .plaintext, label: "", required: true, name: "name", instructions: "", options: [])
        ]
        
        Given(interactor, .getRegistrationFields(willReturn: fields))
        
        await viewModel.getRegistrationFields()
        
        Verify(interactor, 1, .getRegistrationFields())
        XCTAssertEqual(viewModel.isShowProgress, false)
        XCTAssertEqual(viewModel.showError, false)
        XCTAssertEqual(viewModel.errorMessage, nil)
        
    }
    
    func testGetRegistrationFieldsNoInternetError() async throws {
        let interactor = AuthInteractorProtocolMock()
        let router = AuthorizationRouterMock()
        let validator = Validator()
        let viewModel = SignUpViewModel(interactor: interactor,
                                        router: router,
                                        config: ConfigMock(),
                                        cssInjector: CSSInjectorMock(),
                                        validator: validator)
        
        let noInternetError = AFError.sessionInvalidated(error: URLError(.notConnectedToInternet))
        
        Given(interactor, .getRegistrationFields(willThrow: noInternetError))
        
        await viewModel.getRegistrationFields()
        
        Verify(interactor, 1, .getRegistrationFields())
        XCTAssertEqual(viewModel.isShowProgress, false)
        XCTAssertEqual(viewModel.showError, true)
        XCTAssertEqual(viewModel.errorMessage, CoreLocalization.Error.slowOrNoInternetConnection)
    }
    
    func testGetRegistrationFieldsUnknownError() async throws {
        let interactor = AuthInteractorProtocolMock()
        let router = AuthorizationRouterMock()
        let validator = Validator()
        let viewModel = SignUpViewModel(interactor: interactor,
                                        router: router,
                                        config: ConfigMock(),
                                        cssInjector: CSSInjectorMock(),
                                        validator: validator)
        
        Given(interactor, .getRegistrationFields(willThrow: NSError()))
        
        await viewModel.getRegistrationFields()
        
        Verify(interactor, 1, .getRegistrationFields())
        XCTAssertEqual(viewModel.isShowProgress, false)
        XCTAssertEqual(viewModel.showError, true)
        XCTAssertEqual(viewModel.errorMessage, CoreLocalization.Error.unknownError)
    }
    
    func testRegisterUserSuccess() async throws {
        let interactor = AuthInteractorProtocolMock()
        let router = AuthorizationRouterMock()
        let validator = Validator()
        let viewModel = SignUpViewModel(interactor: interactor,
                                        router: router,
                                        config: ConfigMock(),
                                        cssInjector: CSSInjectorMock(),
                                        validator: validator)
        
        Given(interactor, .registerUser(fields: .any, willProduce: {_ in}))
        Given(interactor, .validateRegistrationFields(fields: .any, willReturn: [:]))
        
        await viewModel.registerUser()
        
        Verify(interactor, 1, .validateRegistrationFields(fields: .any))
        Verify(interactor, 1, .registerUser(fields: .any))
        Verify(router, 1, .showMainScreen())
        
        XCTAssertEqual(viewModel.isShowProgress, false)
        XCTAssertEqual(viewModel.showError, false)
    }
    
    func testRegisterUserValidationFailure() async throws {
        let interactor = AuthInteractorProtocolMock()
        let router = AuthorizationRouterMock()
        let validator = Validator()
        let viewModel = SignUpViewModel(interactor: interactor,
                                        router: router,
                                        config: ConfigMock(),
                                        cssInjector: CSSInjectorMock(),
                                        validator: validator)
        
        viewModel.fields = [
            FieldConfiguration(field: .init(type: .email,
                                            label: "email",
                                            required: true,
                                            name: "email",
                                            instructions: "",
                                            options: []))
        ]
        
        Given(interactor, .validateRegistrationFields(fields: .any, willReturn: ["email": "invalid email"]))
        Given(interactor, .registerUser(fields: .any, willProduce: {_ in}))
        
        await viewModel.registerUser()
        
        Verify(interactor, 1, .validateRegistrationFields(fields: .any))
        Verify(interactor, 0, .registerUser(fields: .any))
        Verify(router, 0, .showMainScreen())
        
        XCTAssertEqual(viewModel.isShowProgress, false)
        XCTAssertEqual(viewModel.showError, false)
        XCTAssertFalse(viewModel.fields.first!.error.isEmpty)
    }
    
    func testRegisterUserInvalidCredentials() async throws {
        let interactor = AuthInteractorProtocolMock()
        let router = AuthorizationRouterMock()
        let validator = Validator()
        let viewModel = SignUpViewModel(interactor: interactor,
                                        router: router,
                                        config: ConfigMock(),
                                        cssInjector: CSSInjectorMock(),
                                        validator: validator)
        
        Given(interactor, .validateRegistrationFields(fields: .any, willReturn: [:]))
        Given(interactor, .registerUser(fields: .any, willThrow: APIError.invalidGrant))
        
        await viewModel.registerUser()
        
        Verify(interactor, 1, .validateRegistrationFields(fields: .any))
        Verify(interactor, 1, .registerUser(fields: .any))
        Verify(router, 0, .showMainScreen())
        
        XCTAssertEqual(viewModel.isShowProgress, false)
        XCTAssertEqual(viewModel.showError, true)
        XCTAssertEqual(viewModel.errorMessage, CoreLocalization.Error.invalidCredentials)
    }
    
    func testRegisterUserUnknownError() async throws {
        let interactor = AuthInteractorProtocolMock()
        let router = AuthorizationRouterMock()
        let validator = Validator()
        let viewModel = SignUpViewModel(interactor: interactor,
                                        router: router,
                                        config: ConfigMock(),
                                        cssInjector: CSSInjectorMock(),
                                        validator: validator)
        
        Given(interactor, .validateRegistrationFields(fields: .any, willReturn: [:]))
        Given(interactor, .registerUser(fields: .any, willThrow: NSError()))

        await viewModel.registerUser()
        
        Verify(interactor, 1, .validateRegistrationFields(fields: .any))
        Verify(interactor, 1, .registerUser(fields: .any))
        Verify(router, 0, .showMainScreen())
        
        XCTAssertEqual(viewModel.isShowProgress, false)
        XCTAssertEqual(viewModel.showError, true)
        XCTAssertEqual(viewModel.errorMessage, CoreLocalization.Error.unknownError)
    }
    
    func testRegisterUserNoInternetError() async throws {
        let interactor = AuthInteractorProtocolMock()
        let router = AuthorizationRouterMock()
        let validator = Validator()
        let viewModel = SignUpViewModel(interactor: interactor,
                                        router: router,
                                        config: ConfigMock(),
                                        cssInjector: CSSInjectorMock(),
                                        validator: validator)
        
        let noInternetError = AFError.sessionInvalidated(error: URLError(.notConnectedToInternet))
        
        Given(interactor, .registerUser(fields: .any, willThrow: noInternetError))
        Given(interactor, .validateRegistrationFields(fields: .any, willReturn: [:]))
        
        await viewModel.registerUser()
        
        Verify(interactor, 1, .validateRegistrationFields(fields: .any))
        Verify(interactor, 1, .registerUser(fields: .any))
        Verify(router, 0, .showMainScreen())
        
        XCTAssertEqual(viewModel.isShowProgress, false)
        XCTAssertEqual(viewModel.showError, true)
        XCTAssertEqual(viewModel.errorMessage, CoreLocalization.Error.slowOrNoInternetConnection)
    }
}