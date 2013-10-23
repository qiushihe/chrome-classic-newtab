class ChromeClassicNewTab

  constructor: ($viewport) ->
    @$viewport = $viewport

    @bookmarksBar = new BookmarksBar()
    @bookmarksBar.render(@$viewport)

    @appsList = new AppsList()
    @appsList.render(@$viewport)

    @footer = new Footer()
    @footer.render(@$viewport)

    document.body.addEventListener "click", (event) =>
      unless $(event.target).closest(".bookmarks-popup").length
        @bookmarksBar.hidePopupIfPresent()
    , false

  #
  # Private
  #

  class BookmarksBar

    constructor: ->
      @bookmarksLoaded = new RSVP.Promise (resolve, reject) =>
        chrome.bookmarks.getChildren "1", (bookmarks) =>
          @bookmarks = bookmarks
          resolve(@bookmarks)

    render: (@$viewport) ->
      @$el = document.createElement("div")
      @$el.id = "bookmarks-bar"

      @$viewport.appendChild(@$el)

      @bookmarksLoaded.then =>
        @mainBookmarksList = new BookmarksList(@bookmarks, { delegate: this })
        @mainBookmarksList.render(@$el)

        @otherBookmarksList = new BookmarksList([{ id: "2", title: "Other Bookmarks" }], { delegate: this })
        @otherBookmarksList.render(@$el)
        @otherBookmarksList.$el.className += " other-bookmarks"

    hidePopupIfPresent: ->
      @otherBookmarksList.hidePopupIfPresent()
      @mainBookmarksList.hidePopupIfPresent()

    BookmarksListDidOpenFolder: (bookmarksList) ->
      if bookmarksList == @mainBookmarksList
        @otherBookmarksList.hidePopupIfPresent()
      else
        @mainBookmarksList.hidePopupIfPresent()

    BookmarksListDidMouseOverItem: (bookmarksList, bookmarkItem) ->
      if bookmarkItem.isFolder()
        if bookmarksList == @mainBookmarksList
          @otherBookmarksList.hidePopupIfPresent()
        else
          @mainBookmarksList.hidePopupIfPresent()
      else
        @hidePopupIfPresent()

  class BookmarksList

    constructor: (@bookmarks, @options = {}) ->
      @delegate = @options.delegate

    render: (@$viewport) ->
      @$el = document.createElement("ul")
      @$el.className = "bookmarks-list clearfix"

      for bookmark in @bookmarks
        bookmarkItem = new BookmarkItem(bookmark)
        bookmarkItem.delegate = this
        bookmarkItem.render(@$el)

      @$viewport.appendChild(@$el)

    hidePopupIfPresent: ->
      if @popup
        @popup.hide()
        @popup = null

    openFolder: (bookmarkItem) ->
      chrome.bookmarks.getChildren bookmarkItem.bookmarkId, (bookmarks) =>
        @hidePopupIfPresent()
        @popup = new BookmarksPopup(bookmarks, { folderId: bookmarkItem.bookmarkId })
        @popup.render(bookmarkItem.$link)
      @delegate?.BookmarksListDidOpenFolder?(this)

    BookmarkItemDidClick: (bookmarkItem) ->
      @openFolder(bookmarkItem) if bookmarkItem.isFolder()

    BookmarkItemDidMouseOver: (bookmarkItem) ->
      @hidePopupIfPresent() unless bookmarkItem.isFolder()
      @delegate?.BookmarksListDidMouseOverItem?(this, bookmarkItem)

    BookmarkItemWillClick: (bookmarkItem) ->
      @hidePopupIfPresent()

  class BookmarksPopup

    constructor: (@bookmarks, @options = {}, @flowtipOptions = {}) ->
      @parentPopup = @options.parentPopup
      @folderId = @options.folderId

    render: (@$target) ->
      @$el = document.createElement("ul")
      @$el.className = "bookmarks-list"

      for bookmark in @bookmarks
        bookmarkItem = new BookmarkItem(bookmark)
        bookmarkItem.delegate = this
        bookmarkItem.render(@$el)

      flowtipOptions = if @parentPopup
        {
          region: "right"
          topDisabled: true
          leftDisabled: false
          rightDisabled: false
          bottomDisabled: true
          rootAlign: "edge"
          leftRootAlignOffset: 0
          rightRootAlignOffset: -0.1
          targetAlign: "edge"
          leftTargetAlignOffset: 0
          rightTargetAlignOffset: -0.1
        }
      else
        {
          region: "bottom"
          topDisabled: true
          leftDisabled: true
          rightDisabled: true
          bottomDisabled: false
          rootAlign: "edge"
          rootAlignOffset: 0
          targetAlign: "edge"
          targetAlignOffset: 0
        }

      @flowtip = new FlowTip(_.extend({
        className: "bookmarks-popup"
        hasTail: false
        rotationOffset: 0
        edgeOffset: 10
        targetOffset: 2
        maxHeight: "#{@maxHeight()}px"
      }, flowtipOptions, @flowtipOptions))

      @flowtip.setTooltipContent(@$el)
      @flowtip.setTarget(@$target)
      @flowtip.show()

      @flowtip.content.addEventListener "scroll", =>
        @hidePopupIfPresent()
      , false

    hide: ->
      @hidePopupIfPresent()
      @flowtip.hide()
      @flowtip.destroy()

    hidePopupIfPresent: ->
      if @popup
        @popup.hide()
        @popup = null

    openFolder: (bookmarkItem) ->
      chrome.bookmarks.getChildren bookmarkItem.bookmarkId, (bookmarks) =>
        @hidePopupIfPresent()
        @popup = new BookmarksPopup(bookmarks, {
          parentPopup: this
          folderId: bookmarkItem.bookmarkId
        })
        @popup.render(bookmarkItem.$link)

    maxHeight: ->
      if @parentPopup
        document.body.clientHeight - 20 # edgeOffset x 2
      else
        document.body.clientHeight - 41 # bookmarks-bar height + 1px border

    BookmarkItemDidMouseOver: (bookmarkItem) ->
      if bookmarkItem.isFolder()
        if @popup
          @hidePopupIfPresent() if @popup.folderId != bookmarkItem.bookmarkId
        else
          @openFolder(bookmarkItem)
      else
        @hidePopupIfPresent()

      @parentPopup?.BookmarksPopupDidMouseOverItem?(bookmarkItem)

    BookmarkItemDidMouseOut: (bookmarkItem) ->
      if bookmarkItem.isFolder()
        unless @mouseoutTimeout
          @mouseoutTimeout = _.delay =>
            @hidePopupIfPresent()
            @mouseoutTimeout = null
          , 100

    BookmarkItemWillClick: (bookmarkItem) ->
      if @popup && @popup.folderId != bookmarkItem.bookmarkId
        @hidePopupIfPresent()

    BookmarkItemDidClick: (bookmarkItem) ->
      @parentPopup?.BookmarksPopupDidClickItem?(bookmarkItem)

    BookmarksPopupDidMouseOverItem: (bookmarkItem) ->
      if @mouseoutTimeout
        clearTimeout(@mouseoutTimeout)
        @mouseoutTimeout = null

    BookmarksPopupDidClickItem: (bookmarkItem) ->
      if @parentPopup
        @hidePopupIfPresent()
      else
        @hide()

  class BookmarkItem

    constructor: (@bookmark) ->
      @bookmarkId = @bookmark.id

    render: (@$viewport) ->
      @$el = document.createElement("li")
      @$el.className = "bookmark-item"

      unless @bookmark.url
        @$el.className += " folder-item"

      $link = document.createElement("a")
      $icon = document.createElement("img")
      $label = document.createElement("span")

      $link.className = "clearfix"
      $link.setAttribute("href", @bookmark.url) unless @isFolder()

      $link.addEventListener "mouseover", =>
        if @mouseoutTimeout
          clearTimeout(@mouseoutTimeout)
          @mouseoutTimeout = null
        else
          _.delay =>
            @delegate?.BookmarkItemDidMouseOver?(this)
          , 110
      , false

      $link.addEventListener "mouseout", =>
        unless @mouseoutTimeout
          @mouseoutTimeout = _.delay =>
            @delegate?.BookmarkItemDidMouseOut?(this)
            @mouseoutTimeout = null
          , 100
      , false

      $link.addEventListener "mousedown", =>
        @delegate?.BookmarkItemWillClick?(this)
      , false

      $link.addEventListener "click", =>
        @delegate?.BookmarkItemDidClick?(this)
      , false

      $icon.setAttribute("src", @faviconURL())
      $icon.setAttribute("width", "16")
      $icon.setAttribute("height", "16")

      $label.innerHTML = @bookmark.title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

      $link.appendChild($icon)
      $link.appendChild($label)
      @$el.appendChild($link)

      @$link = $link

      @$viewport.appendChild(@$el)

    isFolder: ->
      !@bookmark.url

    faviconURL: ->
      if @bookmark.url
        "chrome://favicon/#{@bookmark.url}"
      else
        "images/folder.png"

  class AppsList

    constructor: ->
      @appsLoaded = new RSVP.Promise (resolve, reject) =>
        chrome.management.getAll (extensions) =>
          @apps = for extension in extensions when extension.enabled && extension.isApp
            extension
          resolve(@apps)

      window.addEventListener "resize", =>
        @repositionList()

    render: (@viewport) ->
      @el = document.createElement("div")
      @el.id = "apps-wrapper"

      @list = document.createElement("ul")
      @list.id = "apps"
      @list.className = "clearfix"
      @el.appendChild(@list)

      @viewport.appendChild(@el)

      @appsLoaded.then =>
        @renderApps()
        @repositionList()

    renderApps: ->
      @apps.unshift({
        name: "Store"
        url: "https://chrome.google.com/webstore"
        icons: [{
          size: 128
          url: "images/web-store_128.png"
        }]
      })
      for app in @apps
        appItem = new AppItem(app)
        appItem.render(@list)

    repositionList: ->
      @list.style.marginTop = ((@el.clientHeight - @list.clientHeight) / 3) + "px"

  class AppItem

    constructor: ((@app) ->)

    render: (@viewport) ->
      @el = document.createElement("li")
      @el.className = "app-item"

      link = document.createElement("a")
      icon = document.createElement("img")
      label = document.createElement("span")

      link.className = "clearfix"

      if @app.id
        link.addEventListener "click", =>
          chrome.management.launchApp @app.id, ->
            window.close()
        , false
      else if @app.url
        link.setAttribute("href", @app.url)

      icon.setAttribute("src", @iconURL())
      icon.setAttribute("width", "128")
      icon.setAttribute("height", "128")

      label.innerHTML = @app.name.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

      link.appendChild(icon)
      link.appendChild(label)
      @el.appendChild(link)

      @viewport.appendChild(@el)

    iconURL: ->
      size = 0
      largestURL = null
      for icon in @app.icons
        if icon.size > size
          size = icon.size
          largestURL = icon.url
      largestURL

  class Footer

    render: (@$viewport) ->
      @el = document.createElement("div")
      @el.id = "footer"

      img = document.createElement("img")
      img.className = "chrome-logo"
      img.setAttribute("src", "images/chrome.png")
      img.setAttribute("width", "28")
      img.setAttribute("height", "28")
      @el.appendChild(img)

      title = document.createElement("h1")
      title.innerHTML = "chrome"
      @el.appendChild(title)

      storeLink = document.createElement("a")
      storeLink.className = "web-store"
      storeLink.setAttribute("href", "https://chrome.google.com/webstore")
      storeTitle = document.createElement("span")
      storeTitle.innerHTML = "Web Store"
      storeLink.appendChild(storeTitle)
      storeLogo = document.createElement("img")
      storeLogo.setAttribute("src", "images/web-store_20.png")
      storeLogo.setAttribute("width", "20")
      storeLogo.setAttribute("height", "20")
      storeLink.appendChild(storeLogo)
      @el.appendChild(storeLink)

      @$viewport.appendChild(@el)

window.onload = ->
  classicNewTab = new ChromeClassicNewTab(document.body)
