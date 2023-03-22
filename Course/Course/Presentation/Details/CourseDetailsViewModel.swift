//
//  ProfileViewModel.swift
//  Profile
//
//  Created by  Stepanok Ivan on 22.09.2022.
//

import Foundation
import Core
import SwiftUI

public enum CourseState {
    case enrollOpen
    case enrollClose
    case alreadyEnrolled
}

public class CourseDetailsViewModel: ObservableObject {
    
    @Published var courseDetails: CourseDetails?
    @Published private(set) var isShowProgress = false
    @Published var isEnrolled: Bool = false
    @Published var showError: Bool = false
    @Published var certificate: Certificate?
    @Published var isHorisontal: Bool = false
    var errorMessage: String? {
        didSet {
            withAnimation {
                showError = errorMessage != nil
            }
        }
    }
    
    private let interactor: CourseInteractorProtocol
    let router: CourseRouter
    let config: Config
    let cssInjector: CSSInjector
    public let connectivity: ConnectivityProtocol
    
    public init(interactor: CourseInteractorProtocol,
                router: CourseRouter,
                config: Config,
                cssInjector: CSSInjector,
                connectivity: ConnectivityProtocol) {
        self.interactor = interactor
        self.router = router
        self.config = config
        self.cssInjector = cssInjector
        self.connectivity = connectivity
    }
    
    @MainActor
    func getCourseDetail(courseID: String, withProgress: Bool = true) async {
        isShowProgress = withProgress
        do {
            if connectivity.isInternetAvaliable {
                courseDetails = try await interactor.getCourseDetails(courseID: courseID)
                async let enrolled = interactor.getEnrollments()
                self.isEnrolled = try await enrolled.contains(where: { $0.courseID == courseID })
                self.certificate = try await enrolled.first(where: { $0.courseID == courseID })?.certificate
                isShowProgress = false
            } else {
                courseDetails = try await interactor.getCourseDetailsOffline(courseID: courseID)
                async let enrolled = interactor.getEnrollmentsOffline()
                self.isEnrolled = try await enrolled.contains(where: { $0.courseID == courseID })
                self.certificate = try await enrolled.first(where: { $0.courseID == courseID })?.certificate
                isShowProgress = false
            }
        } catch let error {
            isShowProgress = false
            if error.isInternetError || error is NoCachedDataError {
                errorMessage = CoreLocalization.Error.slowOrNoInternetConnection
            } else {
                errorMessage = CoreLocalization.Error.unknownError
            }
        }
    }
    
    func courseState() -> CourseState {
        if !isEnrolled {
            if let enrollmentStart = courseDetails?.enrollmentStart, let enrollmentEnd = courseDetails?.enrollmentEnd {
                let enrollmentsRange = DateInterval(start: enrollmentStart, end: enrollmentEnd)
                if enrollmentsRange.contains(Date()) {
                    return .enrollOpen
                } else {
                    return .enrollClose
                }
            } else {
                return .enrollOpen
            }
        } else {
            return .alreadyEnrolled
        }
    }
    
    @MainActor
    func enrollToCourse(id: String) async {
        do {
            _ = try await interactor.enrollToCourse(courseID: id)
            isEnrolled = true
            NotificationCenter.default.post(name: .onCourseEnrolled, object: id)
        } catch let error {
            if error.isInternetError || error is NoCachedDataError {
                errorMessage = CoreLocalization.Error.slowOrNoInternetConnection
            } else {
                errorMessage = CoreLocalization.Error.unknownError
            }
        }
    }
}