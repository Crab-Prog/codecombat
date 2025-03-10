dynamicRequire = require('lib/dynamicRequire')
locale = require 'locale/locale'
globalVar = require 'core/globalVar'

go = (path, options) -> -> @routeDirectly path, arguments, options

redirect = (path) -> ->
  delete window.alreadyLoadedView
  @navigate(path + document.location.search, { trigger: true, replace: true })

utils = require './utils'
ViewLoadTimer = require 'core/ViewLoadTimer'

module.exports = class CocoRouter extends Backbone.Router

  initialize: ->
    # http://nerds.airbnb.com/how-to-add-google-analytics-page-tracking-to-57536
    @bind 'route', @_trackPageView
    Backbone.Mediator.subscribe 'router:navigate', @onNavigate, @
    @initializeSocialMediaServices = _.once @initializeSocialMediaServices

    # Lazily require and load VueRouter because it currently loads all of its dependencies
    # in a single Webpack bundle.  The app initialization logic assumes that all Views are
    # loaded lazily and thus will not be initialized as part of the initial page load.
    #
    # Because Vue router and its dependencies are loaded in a single bundle any CocoViews
    # that are loaded via the Vue router are initialized too early.  Delaying loading of
    # Vue router delays initialization of dependent CocoViews until an appropriate time.
    #
    # TODO Integrate webpack bundle loading with vueRouter and load this normally
    @vueRouter = require('app/core/vueRouter').default()

  routes:
    '': ->
      if window.serverConfig.picoCTF
        return @routeDirectly 'play/CampaignView', ['picoctf'], {}
      if utils.getQueryVariable 'hour_of_code'
        delete window.alreadyLoadedView
        return @navigate "/play?hour_of_code=true", {trigger: true, replace: true}
      unless me.isAnonymous() or me.isStudent() or me.isTeacher() or me.isAdmin() or me.hasSubscription() or me.isAPIClient()
        delete window.alreadyLoadedView
        return @navigate "/premium", {trigger: true, replace: true}
      if me.isAPIClient()
        delete window.alreadyLoadedView
        #return @navigate "/league/#{me.get('clans')?[0] ? ''}apiclient-data", {trigger: true, replace: true}  # Once we make sure all students have been associated with their API creators
        return @navigate "/api-dashboard", {trigger: true, replace: true}
      if me.useChinaHomeView()
        delete window.alreadyLoadedView
        return @routeDirectly('HomeCNView', [])
      return @routeDirectly('HomeView', [])

    'about': go('AboutView')
    'contact-cn': go('ContactCNView')
    'china-bridge': go('ChinaBridgeView')

    'account': go('account/MainAccountView')
    'account/oauth-aiyouth': go('account/OAuthAIYouthView')

    'account/settings': go('account/AccountSettingsRootView')
    'account/unsubscribe': go('account/UnsubscribeView')
    'account/payments': go('account/PaymentsView')
    'account/subscription': go('account/SubscriptionView', { redirectStudents: true, redirectTeachers: true })
    'account/invoices': go('account/InvoicesView')
    'account/prepaid': go('account/PrepaidView')

    'licensor': go('LicensorView')

    'admin': go('admin/MainAdminView')
    'admin/clas': go('admin/CLAsView')
    'admin/classroom-content': go('admin/AdminClassroomContentView')
    'admin/classroom-levels': go('admin/AdminClassroomLevelsView')
    'admin/classrooms-progress': go('admin/AdminClassroomsProgressView')
    'admin/design-elements': go('admin/DesignElementsView')
    'admin/files': go('admin/FilesView')
    'admin/analytics': go('admin/AnalyticsView')
    'admin/analytics/subscriptions': go('admin/AnalyticsSubscriptionsView')
    'admin/level-hints': go('admin/AdminLevelHintsView')
    'admin/level-sessions': go('admin/LevelSessionsView')
    'admin/school-counts': go('admin/SchoolCountsView')
    'admin/school-licenses': go('admin/SchoolLicensesView')
    'admin/sub-cancellations': go('admin/AdminSubCancellationsView')
    'admin/base': go('admin/BaseView')
    'admin/demo-requests': go('admin/DemoRequestsView')
    'admin/trial-requests': go('admin/TrialRequestsView')
    'admin/user-code-problems': go('admin/UserCodeProblemsView')
    'admin/pending-patches': go('admin/PendingPatchesView')
    'admin/codelogs': go('admin/CodeLogsView')
    'admin/skipped-contacts': go('admin/SkippedContactsView')
    'admin/outcomes-report-result': go('admin/OutcomeReportResultView')
    'admin/outcomes-report': go('admin/OutcomesReportView')
    'admin/clan(/:clanID)': go('core/SingletonAppVueComponentView')

    'apcsp(/*subpath)': go('teachers/DynamicAPCSPView')

    'api-dashboard': go('core/SingletonAppVueComponentView')

    'artisans': go('artisans/ArtisansView')

    'artisans/level-tasks': go('artisans/LevelTasksView')
    'artisans/solution-problems': go('artisans/SolutionProblemsView')
    'artisans/thang-tasks': go('artisans/ThangTasksView')
    'artisans/level-concepts': go('artisans/LevelConceptMap')
    'artisans/level-guides': go('artisans/LevelGuidesView')
    'artisans/student-solutions': go('artisans/StudentSolutionsView')
    'artisans/tag-test': go('artisans/TagTestView')
    'artisans/bulk-level-editor': go('artisans/BulkLevelEditView')
    'artisans/sandbox': go('artisans/SandboxView')
    'artisans/bulk-level-editor/:campaign': go('artisans/BulkLevelEditView')
    'artisans/arena-balancer(/:levelSlug)': go('artisans/ArenaBalancerView')

    'careers': => window.location.href = 'https://jobs.lever.co/codecombat'
    'Careers': => window.location.href = 'https://jobs.lever.co/codecombat'

    'cla': go('CLAView')

    'clans': go('clans/ClansView', { redirectStudents: true })
    'clans/:clanID': go('clans/ClanDetailsView', { redirectStudents: true })

    'community': go('CommunityView')

    'contribute': go('contribute/MainContributeView')
    'contribute/adventurer': go('contribute/AdventurerView')
    'contribute/ambassador': go('contribute/AmbassadorView')
    'contribute/archmage': go('contribute/ArchmageView')
    'contribute/artisan': go('contribute/ArtisanView')
    'contribute/diplomat': go('contribute/DiplomatView')
    'contribute/scribe': go('contribute/ScribeView')

    'courses': redirect('/students') # Redirected 9/3/16
    'Courses': redirect('/students') # Redirected 9/3/16
    'courses/students': redirect('/students') # Redirected 9/3/16
    'courses/teachers': redirect('/teachers/classes')
    'courses/purchase': redirect('/teachers/licenses')
    'courses/enroll(/:courseID)': redirect('/teachers/licenses')
    'courses/update-account': redirect('students/update-account') # Redirected 9/3/16
    'courses/:classroomID': -> @navigate("/students/#{arguments[0]}", {trigger: true, replace: true}) # Redirected 9/3/16
    'courses/:courseID/:courseInstanceID': -> @navigate("/students/#{arguments[0]}/#{arguments[1]}", {trigger: true, replace: true}) # Redirected 9/3/16

    'db/*path': 'routeToServer'
    'docs/components': go('editor/docs/ComponentsDocumentationView')
    'docs/systems': go('editor/docs/SystemsDocumentationView')

    'editor': go('CommunityView')

    'editor/achievement': go('editor/achievement/AchievementSearchView')
    'editor/achievement/:articleID': go('editor/achievement/AchievementEditView')
    'editor/article': go('editor/article/ArticleSearchView')
    'editor/article/preview': go('editor/article/ArticlePreviewView')
    'editor/article/:articleID': go('editor/article/ArticleEditView')
    'editor/level': go('editor/level/LevelSearchView')
    'editor/level/:levelID': go('editor/level/LevelEditView')
    'editor/thang': go('editor/thang/ThangTypeSearchView')
    'editor/thang/:thangID': go('editor/thang/ThangTypeEditView')
    'editor/campaign/:campaignID': go('editor/campaign/CampaignEditorView')
    'editor/poll': go('editor/poll/PollSearchView')
    'editor/poll/:articleID': go('editor/poll/PollEditView')
    'editor/verifier(/:levelID)': go('editor/verifier/VerifierView')
    'editor/i18n-verifier(/:levelID)': go('editor/verifier/i18nVerifierView')
    'editor/course': go('editor/course/CourseSearchView')
    'editor/course/:courseID': go('editor/course/CourseEditView')

    'etc': redirect('/teachers/demo')
    'demo': redirect('/teachers/demo')
    'quote': redirect('/teachers/demo')

    'file/*path': 'routeToServer'

    'github/*path': 'routeToServer'

    'hoc': -> @navigate "/play/hoc-2018", {trigger: true, replace: true}
    'play/hoc-2020': -> @navigate "/play/hoc-2018", {trigger: true, replace: true} # Added to handle HoC PDF
    'home': if me.useChinaHomeView() then go('HomeCNView') else go('HomeView')

    'i18n': go('i18n/I18NHomeView')
    'i18n/thang/:handle': go('i18n/I18NEditThangTypeView')
    'i18n/component/:handle': go('i18n/I18NEditComponentView')
    'i18n/level/:handle': go('i18n/I18NEditLevelView')
    'i18n/achievement/:handle': go('i18n/I18NEditAchievementView')
    'i18n/campaign/:handle': go('i18n/I18NEditCampaignView')
    'i18n/poll/:handle': go('i18n/I18NEditPollView')
    'i18n/course/:handle': go('i18n/I18NEditCourseView')
    'i18n/product/:handle': go('i18n/I18NEditProductView')
    'i18n/article/:handle': go('i18n/I18NEditArticleView')

    'identify': go('user/IdentifyView')
    'il-signup': go('account/IsraelSignupView')

    'impact': () ->
      @routeDirectly('PageImpact', [], { vueRoute: true, baseTemplate: 'base-flat' })

    'league/academica': redirect('/league/autoclan-school-network-academica') # Redirect for Academica.
    'league/kipp': redirect('/league/autoclan-school-network-kipp') # Redirect for KIPP.
    'league(/*subpath)': go('core/SingletonAppVueComponentView')

    'legal': go('LegalView')

    'logout': 'logout'

    'minigames/conditionals': go('minigames/ConditionalMinigameView')

    'parents': go('core/SingletonAppVueComponentView')
    'live-classes': go('core/SingletonAppVueComponentView')

    'outcomes-report(/*subpath)': go('core/SingletonAppVueComponentView')

    # Warning: In production debugging of third party iframe!
    'temporary-debug-timetap': go('core/SingletonAppVueComponentView')

    'paypal/subscribe-callback': go('play/CampaignView')
    'paypal/cancel-callback': go('account/SubscriptionView')

    'tournaments/:pageType/:objectId': go('ladder/MainTournamentView')

    'play(/)': go('play/CampaignView', { redirectStudents: true, redirectTeachers: true }) # extra slash is to get Facebook app to work
    'play/ladder/:levelID/:leagueType/:leagueID': go('ladder/LadderView')
    'play/ladder/:levelID': go('ladder/LadderView')
    'play/ladder': go('ladder/MainLadderView')
    'play/level/:levelID': go('play/level/PlayLevelView')
    'play/video/level/:levelID': go('play/level/PlayLevelVideoView')
    'play/game-dev-level/:sessionID': go('play/level/PlayGameDevLevelView')
    'play/web-dev-level/:sessionID': go('play/level/PlayWebDevLevelView')
    'play/game-dev-level/:levelID/:sessionID': (levelID, sessionID, queryString) ->
      @navigate("play/game-dev-level/#{sessionID}?#{queryString}", { trigger: true, replace: true })
    'play/web-dev-level/:levelID/:sessionID': (levelID, sessionID, queryString) ->
      @navigate("play/web-dev-level/#{sessionID}?#{queryString}", { trigger: true, replace: true })
    'play/spectate/:levelID': go('play/SpectateView')
    'play/:map': go('play/CampaignView')

    'premium': go('PremiumFeaturesView', { redirectStudents: true, redirectTeachers: true })
    'Premium': go('PremiumFeaturesView', { redirectStudents: true, redirectTeachers: true })

    'preview': if me.useChinaHomeView() then go('HomeCNView') else go('HomeView')

    'privacy': go('PrivacyView')

    'schools': if me.useChinaHomeView() then go('HomeCNView') else go('HomeView')
    'seen': if me.useChinaHomeView() then go('HomeCNView') else go('HomeView')
    'SEEN': if me.useChinaHomeView() then go('HomeCNView') else go('HomeView')

    'students': go('courses/CoursesView', { redirectTeachers: true })
    'students/update-account': go('courses/CoursesUpdateAccountView', { redirectTeachers: true })
    'students/project-gallery/:courseInstanceID': go('courses/ProjectGalleryView')
    'students/assessments/:classroomID': go('courses/StudentAssessmentsView')
    'students/videos/:courseID/:courseName': go('courses/CourseVideosView')
    'students/:classroomID': go('courses/ClassroomView', { redirectTeachers: true, studentsOnly: true })
    'students/:courseID/:courseInstanceID': go('courses/CourseDetailsView', { redirectTeachers: true, studentsOnly: true })

    'teachers': redirect('/teachers/classes')
    'teachers/classes': go('courses/TeacherClassesView', { redirectStudents: true, teachersOnly: true })
    'teachers/classes/:classroomID/:studentID': go('teachers/TeacherStudentView', { redirectStudents: true, teachersOnly: true })
    'teachers/classes/:classroomID': go('courses/TeacherClassView', { redirectStudents: true, teachersOnly: true })
    'teachers/courses': go('courses/TeacherCoursesView', { redirectStudents: true })
    'teachers/course-solution/:courseID/:language': go('teachers/TeacherCourseSolutionView', { redirectStudents: true })
    'teachers/demo': redirect('/teachers/quote')
    'teachers/enrollments': redirect('/teachers/licenses')
    'teachers/hour-of-code': go('special_event/HoC2018View')
    'teachers/licenses': go('courses/EnrollmentsView', { redirectStudents: true, teachersOnly: true })
    'teachers/freetrial': go('teachers/RequestQuoteView', { redirectStudents: true })
    'teachers/quote': go('teachers/RequestQuoteView', { redirectStudents: true })
    'teachers/resources': go('teachers/ResourceHubView', { redirectStudents: true })
    'teachers/resources/ap-cs-principles': go('teachers/ApCsPrinciplesView', { redirectStudents: true })
    'teachers/resources/:name': go('teachers/MarkdownResourceView', { redirectStudents: true })
    'teachers/signup': ->
      return @routeDirectly('teachers/CreateTeacherAccountView', []) if me.isAnonymous()
      return @navigate('/students', {trigger: true, replace: true}) if me.isStudent() and not me.isAdmin()
      @navigate('/teachers/update-account', {trigger: true, replace: true})
    'teachers/update-account': ->
      return @navigate('/teachers/signup', {trigger: true, replace: true}) if me.isAnonymous()
      return @navigate('/students', {trigger: true, replace: true}) if me.isStudent() and not me.isAdmin()
      @routeDirectly('teachers/ConvertToTeacherAccountView', [])

    'school-administrator(/*subpath)': go('core/SingletonAppVueComponentView')
    'cinematicplaceholder/:levelSlug': go('core/SingletonAppVueComponentView')

    'test(/*subpath)': go('TestView')

    'user/:slugOrID': go('user/MainUserView')
    'certificates/:slugOrID': go('user/CertificatesView')
    'certificates/:id/anon': go('user/AnonCertificatesView')

    'user/:userID/verify/:verificationCode': go('user/EmailVerifiedView')
    'user/:userID/opt-in/:verificationCode': go('user/UserOptInView')

    'payments/*path': go('core/SingletonAppVueComponentView')

    '*name/': 'removeTrailingSlash'
    '*name': go('NotFoundView')

  routeToServer: (e) ->
    window.location.href = window.location.href

  removeTrailingSlash: (e) ->
    @navigate e, {trigger: true}

  routeDirectly: (path, args=[], options={}) ->
    @vueRouter.push("/#{Backbone.history.getFragment()}")

    if window.alreadyLoadedView
      path = window.alreadyLoadedView
    @viewLoad = new ViewLoadTimer() unless options.recursive
    if options.redirectStudents and me.isStudent() and not me.isAdmin()
      return @redirectHome()
    if options.redirectTeachers and me.isTeacher() and not me.isAdmin()
      return @redirectHome()
    if options.teachersOnly and not (me.isTeacher() or me.isAdmin())
      return @routeDirectly('teachers/RestrictedToTeachersView')
    if options.studentsOnly and not (me.isStudent() or me.isAdmin())
      return @routeDirectly('courses/RestrictedToStudentsView')
    leavingMessage = _.result(globalVar.currentView, 'onLeaveMessage')
    if leavingMessage
      # Custom messages don't work any more, main browsers just show generic ones. So, this could be refactored.
      if not confirm(leavingMessage)
        return @navigate(this.path, {replace: true})
      else
        globalVar.currentView.onLeaveMessage = _.noop # to stop repeat confirm calls

    # TODO: Combine these two?
    if features.playViewsOnly and not (_.string.startsWith(document.location.pathname, '/play') or document.location.pathname is '/admin')
      delete window.alreadyLoadedView
      return @navigate('/play', { trigger: true, replace: true })
    if features.playOnly and not /^(views)?\/?play/.test(path)
      delete window.alreadyLoadedView
      path = 'play/CampaignView'

    path = "views/#{path}" if not _.string.startsWith(path, 'views/')
    Promise.all([
      dynamicRequire[path](), # Load the view file
      # The locale load is already initialized by `application`, just need the promise
      locale.load(me.get('preferredLanguage', true))
    ]).then ([ViewClass]) =>
      return go('NotFoundView') if not ViewClass

      SingletonAppVueComponentView = require('views/core/SingletonAppVueComponentView').default
      if ViewClass == SingletonAppVueComponentView && globalVar.currentView instanceof SingletonAppVueComponentView
        # The SingletonAppVueComponentView maintains its own Vue app with its own routing layer.  If it
        # is already routed we do not need to route again
        console.debug("Skipping route in Backbone - delegating to Vue app")
        return
      else if options.vueRoute  # Routing to a vue component using VueComponentView
        vueComponentView = require 'views/core/VueComponentView'
        view = new vueComponentView(ViewClass.default, options, args...)
      else
        Klass = if ViewClass.default then ViewClass.default else ViewClass
        view = new Klass(options, args...)  # options, then any path fragment args

      view.render()

      if window.alreadyLoadedView
        console.log "Need to merge view"
        delete window.alreadyLoadedView
        @mergeView(view)
      else
        @openView(view)

      @viewLoad.setView(view)
      @viewLoad.record()
    .catch (err) ->
      console.log err

  redirectHome: ->
    delete window.alreadyLoadedView
    homeUrl = switch
      #when me.isAPIClient() then "/league/#{me.get('clans')?[0] ? ''}#apiclient-data"  # Once we make sure all students have been associated with their API creators
      when me.isAPIClient() then "/api-dashboard"
      when me.isStudent() then '/students'
      when me.isTeacher() then '/teachers'
      else '/'
    @navigate(homeUrl, {trigger: true, replace: true})

  openView: (view) ->
    @closeCurrentView()
    $('#page-container').empty().append view.el
    @activateTab()
    @didOpenView view

  mergeView: (view) ->
    unless view.mergeWithPrerendered?
      return @openView(view)

    target = $('#page-container>div')
    view.mergeWithPrerendered target
    view.setElement target[0]
    @didOpenView view

  didOpenView: (view) ->
    globalVar.currentView = view
    view.afterInsert()
    view.didReappear()
    @path = document.location.pathname + document.location.search
    @trigger 'did-load-route'

  closeCurrentView: ->
    if globalVar.currentView?.reloadOnClose
      return document.location.reload()
    currentModal?.hide?()
    return unless globalVar.currentView?
    globalVar.currentView.modalClosed()
    globalVar.currentView.destroy()
    $('.popover').popover 'hide'
    $('#flying-focus').css({top: 0, left: 0}) # otherwise it might make the page unnecessarily tall
    _.delay (->
      $('html')[0].scrollTop = 0
      $('body')[0].scrollTop = 0
    ), 10

  initializeSocialMediaServices: ->
    return if application.testing or application.demoing or not me.useSocialSignOn()
    application.facebookHandler.loadAPI()
    application.gplusHandler.loadAPI()
    require('core/services/twitter')()

  activateTab: ->
    base = _.string.words(document.location.pathname[1..], '/')[0]
    $("ul.nav li.#{base}").addClass('active')

  _trackPageView: ->
    window.tracker?.trackPageView()

  onNavigate: (e, recursive=false) ->
    @viewLoad = new ViewLoadTimer() unless recursive
    if _.isString e.viewClass
      dynamicRequire[e.viewClass]().then (viewClass) =>
        @onNavigate(_.assign({}, e, {viewClass}), true)
      return

    manualView = e.view or e.viewClass
    if (e.route is document.location.pathname) and not manualView
      return document.location.reload()
    @navigate e.route, {trigger: not manualView}
    @_trackPageView()
    return unless manualView
    if e.viewClass
      args = e.viewArgs or []
      Klass = if e.viewClass.default then e.viewClass.default else e.viewClass
      view = new Klass(args...)
      view.render()
      @openView view
      @viewLoad.setView(view)
    else
      @openView e.view
      @viewLoad.setView(e.view)
    @viewLoad.record()

  navigate: (fragment, options) ->
    super fragment, options
    Backbone.Mediator.publish 'router:navigated', route: fragment

  reload: ->
    document.location.reload()

  logout: ->
    me.logout()
    @navigate('/', { trigger: true })
