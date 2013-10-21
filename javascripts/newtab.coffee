class ChromeClassicNewTab

  constructor: ($viewport) ->
    @$viewport = $viewport

    @bookmarksBar = new BookmarksBar()
    @bookmarksBar.render(@$viewport)

    @appsList = new AppsList()
    @appsList.render(@$viewport)

    @footer = new Footer()
    @footer.render(@$viewport)

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
        bookmarksList = new BookmarksList(@bookmarks)
        bookmarksList.render(@$el)

        otherBookmarksList = new BookmarksList([{ id: "2", title: "Other Bookmarks" }])
        otherBookmarksList.render(@$el)
        otherBookmarksList.$el.className += " other-bookmarks"

  class BookmarksList

    constructor: ((@bookmarks) ->)

    render: (@$viewport) ->
      @$el = document.createElement("ul")
      @$el.className = "bookmarks-list clearfix"

      for bookmark in @bookmarks
        bookmarkItem = new BookmarkItem(bookmark)
        bookmarkItem.delegate = this
        bookmarkItem.render(@$el)

      @$viewport.appendChild(@$el)

    BookmarkItemDidClickFolder: (bookmarkItem) ->
      chrome.bookmarks.getChildren bookmarkItem.bookmark.id, (bookmarks) =>
        popup = new BookmarksPopup(bookmarks, { region: "bottom" })
        popup.render(bookmarkItem.$el)

  class BookmarksPopup

    constructor: ((@bookmarks, @options = {}) ->)

    render: (@$target) ->
      @$el = document.createElement("ul")
      @$el.className = "bookmarks-list"

      for bookmark in @bookmarks
        bookmarkItem = new BookmarkItem(bookmark)
        bookmarkItem.delegate = this
        bookmarkItem.render(@$el)

      @flowtip = new FlowTip(_.extend(@options, {
        hasTail: false
      }))

      @flowtip.setTooltipContent(@$el)
      @flowtip.setTarget(@$target)
      @flowtip.show()

  class BookmarkItem

    constructor: ((@bookmark) ->)

    render: (@$viewport) ->
      @$el = document.createElement("li")
      @$el.className = "bookmark-item"

      unless @bookmark.url
        @$el.className += " folder-item"

      $link = document.createElement("a")
      $icon = document.createElement("img")
      $label = document.createElement("span")

      $link.className = "clearfix"
      if @bookmark.url
        $link.setAttribute("href", @bookmark.url)
      else
        $link.addEventListener "click", =>
          @delegate?.BookmarkItemDidClickFolder?(this)
        , false

      $icon.setAttribute("src", @faviconURL())
      $icon.setAttribute("width", "16")
      $icon.setAttribute("height", "16")

      $label.innerHTML = @bookmark.title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

      $link.appendChild($icon)
      $link.appendChild($label)
      @$el.appendChild($link)

      @$viewport.appendChild(@$el)

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
