//
//  CourseDetailsView.swift
//  CourseDetailsView
//
//  Created by  Stepanok Ivan on 22.09.2022.
//

import SwiftUI
import Core
import Kingfisher
import WebKit

public struct CourseDetailsView: View {
    
    @ObservedObject private var viewModel: CourseDetailsViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var animate = false
    @State private var showCourse = false
    private var title: String
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    private var courseID: String
    
    private func updateOrientation() {
        viewModel.isHorisontal =
        UIDevice.current.orientation == .landscapeLeft
        || UIDevice.current.orientation == .landscapeRight
    }
    
    public init(viewModel: CourseDetailsViewModel, courseID: String, title: String) {
        self.viewModel = viewModel
        self.title = title
        self.courseID = courseID
        Task {
            await viewModel.getCourseDetail(courseID: courseID)
        }
        self.updateOrientation()
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            
            // MARK: - Page name
            VStack(alignment: .center) {
                NavigationBar(title: CourseLocalization.Details.title,
                                     leftButtonAction: { viewModel.router.back() })
                    .onReceive(NotificationCenter
                        .Publisher(center: .default,
                                   name: UIDevice.orientationDidChangeNotification)) { _ in
                        updateOrientation()
                    }

                // MARK: - Page Body
                GeometryReader { proxy in
                    if viewModel.isShowProgress {
                        HStack(alignment: .center) {
                            ProgressBar(size: 40, lineWidth: 8)
                                .padding(.top, 200)
                                .padding(.horizontal)
                        }.frame(width: proxy.size.width)
                    } else {
                        RefreshableScrollViewCompat(action: {
                            await viewModel.getCourseDetail(courseID: courseID, withProgress: isIOS14)
                        }) {
                            VStack(alignment: .leading) {
                                if let courseDetails = viewModel.courseDetails {
                                    if idiom == .pad && viewModel.isHorisontal {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(courseDetails.courseDescription)
                                                    .font(Theme.Fonts.labelSmall)
                                                    .padding(.horizontal, 26)
                                                
                                                Text(courseDetails.courseTitle)
                                                    .font(Theme.Fonts.titleLarge)
                                                    .padding(.horizontal, 26)
                                                
                                                Text(courseDetails.org)
                                                    .font(Theme.Fonts.labelMedium)
                                                    .foregroundColor(CoreAssets.accentColor.swiftUIColor)
                                                    .padding(.horizontal, 26)
                                                    .padding(.top, 10)
                                                Spacer()
                                                switch viewModel.courseState() {
                                                case .enrollOpen:
                                                    StyledButton(CourseLocalization.Details.enrollNow, action: {
                                                        Task {
                                                            await viewModel.enrollToCourse(id: courseDetails.courseID)
                                                        }
                                                    })
                                                    .padding(16)
                                                    .frame(maxWidth: .infinity)
                                                case .enrollClose:
                                                    Text(CourseLocalization.Details.enrollmentDateIsOver)
                                                        .multilineTextAlignment(.center)
                                                        .font(Theme.Fonts.titleSmall)
                                                        .cardStyle()
                                                        .padding(.vertical, 24)
                                                case .alreadyEnrolled:
                                                    StyledButton(CourseLocalization.Details.viewCourse, action: {
                                                        showCourse = true
                                                        
                                                        viewModel.router.showCourseScreens(
                                                            courseID: courseDetails.courseID,
                                                            isActive: nil,
                                                            courseStart: courseDetails.courseStart,
                                                            courseEnd: courseDetails.courseEnd,
                                                            enrollmentStart: courseDetails.enrollmentStart,
                                                            enrollmentEnd: courseDetails.enrollmentEnd,
                                                            title: title,
                                                            courseBanner: courseDetails.courseBannerURL,
                                                            certificate: viewModel.certificate
                                                        )
                                                        
                                                    })
                                                    .padding(16)
                                                }
                                            }
                                            VStack {
                                                let image = CoreAssets.noCourseImage.image
                                                KFImage(URL(string: courseDetails.courseBannerURL))
                                                    .onFailureImage(CoreAssets.noCourseImage.image)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: idiom == .pad ? 312 : proxy.size.width - 12)
                                                    .opacity(animate ? 1 : 0)
                                                    .onAppear {
                                                        withAnimation(.linear(duration: 0.5)) {
                                                            animate = true
                                                        }
                                                    }
                                            }.aspectRatio(CGSize(width: 16, height: 8.5), contentMode: .fill)
                                                .frame(maxHeight: 250)
                                                .cornerRadius(12)
                                                .padding(.horizontal, 6)
                                                .padding(.top, 7)
                                            
                                        }
                                    } else {
                                        VStack {
                                            KFImage(URL(string: courseDetails.courseBannerURL))
                                                .onFailureImage(CoreAssets.noCourseImage.image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: idiom == .pad ? 540 : proxy.size.width - 12)
                                                .opacity(animate ? 1 : 0)
                                                .onAppear {
                                                    withAnimation(.linear(duration: 0.5)) {
                                                        animate = true
                                                    }
                                                }
                                        }.aspectRatio(CGSize(width: 16, height: 8.5), contentMode: .fill)
                                            .frame(maxHeight: 250)
                                            .cornerRadius(12)
                                            .padding(.horizontal, 6)
                                            .padding(.top, 7)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        switch viewModel.courseState() {
                                        case .enrollOpen:
                                            StyledButton(CourseLocalization.Details.enrollNow, action: {
                                                Task {
                                                    await viewModel.enrollToCourse(id: courseDetails.courseID)
                                                }
                                            })
                                            .padding(16)
                                            .frame(maxWidth: .infinity)
                                        case .enrollClose:
                                            Text(CourseLocalization.Details.enrollmentDateIsOver)
                                                .multilineTextAlignment(.center)
                                                .font(Theme.Fonts.titleSmall)
                                                .cardStyle()
                                                .padding(.vertical, 24)
                                        case .alreadyEnrolled:
                                            StyledButton(CourseLocalization.Details.viewCourse, action: {
                                                showCourse = true
                                                
                                                viewModel.router.showCourseScreens(
                                                    courseID: courseDetails.courseID,
                                                    isActive: nil,
                                                    courseStart: courseDetails.courseStart,
                                                    courseEnd: courseDetails.courseEnd,
                                                    enrollmentStart: courseDetails.enrollmentStart,
                                                    enrollmentEnd: courseDetails.enrollmentEnd,
                                                    title: title,
                                                    courseBanner: courseDetails.courseBannerURL,
                                                    certificate: viewModel.certificate
                                                )
                                                
                                            })
                                            .padding(16)
                                        }
                                        Text(courseDetails.courseDescription)
                                            .font(Theme.Fonts.labelSmall)
                                            .padding(.horizontal, 26)
                                        
                                        Text(courseDetails.courseTitle)
                                            .font(Theme.Fonts.titleLarge)
                                            .padding(.horizontal, 26)
                                        
                                        Text(courseDetails.org)
                                            .font(Theme.Fonts.labelMedium)
                                            .foregroundColor(CoreAssets.accentColor.swiftUIColor)
                                            .padding(.horizontal, 26)
                                            .padding(.top, 10)
                                    }
                                    
                                    // MARK: - HTML Embed
                                    VStack {
                                        HTMLFormattedText(
                                            viewModel.cssInjector.injectCSS(
                                                colorScheme: colorScheme,
                                                html: courseDetails.overviewHTML,
                                                type: .discovery, screenWidth: proxy.size.width)
                                        )
                                        .ignoresSafeArea()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 24)
                                }
                            }
                        }.frameLimit()
                            .onRightSwipeGesture {
                                viewModel.router.back()
                            }
                        Spacer(minLength: 84)
                    }
                }
            }
            
            // MARK: - Offline mode SnackBar
                OfflineSnackBarView(connectivity: viewModel.connectivity,
                                    reloadAction: {
                    await viewModel.getCourseDetail(courseID: courseID, withProgress: isIOS14)
                })
            
            // MARK: - Error Alert
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }
                .padding(.bottom, viewModel.connectivity.isInternetAvaliable
                         ? 0 : OfflineSnackBarView.height)
                .transition(.move(edge: .bottom))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.errorMessage = nil
                    }
                }
            }
        }
        .background(
            CoreAssets.background.swiftUIColor
                .ignoresSafeArea()
        )
    }
}

#if DEBUG
// swiftlint:disable all
struct CourseDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = CourseDetailsViewModel(
            interactor: CourseInteractor.mock,
            router: CourseRouterMock(),
            config: ConfigMock(),
            cssInjector: CSSInjectorMock(),
            connectivity: Connectivity()
        )
        
        CourseDetailsView(
            viewModel: vm,
            courseID: "courseID",
            title: "Course title"
        )
        .preferredColorScheme(.light)
        .previewDisplayName("CourseDetailsView Light")
        
        CourseDetailsView(
            viewModel: vm,
            courseID: "courseID",
            title: "Course title"
        )
        .preferredColorScheme(.dark)
        .previewDisplayName("CourseDetailsView Dark")
    }
}
#endif