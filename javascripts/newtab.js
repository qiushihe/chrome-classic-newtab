// Generated by CoffeeScript 1.6.3
(function() {
  var ChromeClassicNewTab;

  ChromeClassicNewTab = (function() {
    var AppItem, AppsList, BookmarkItem, BookmarksBar, BookmarksList, BookmarksPopup, Footer, _class, _class1, _class2, _ref, _ref1, _ref2;

    function ChromeClassicNewTab($viewport) {
      this.$viewport = $viewport;
      this.bookmarksBar = new BookmarksBar();
      this.bookmarksBar.render(this.$viewport);
      this.appsList = new AppsList();
      this.appsList.render(this.$viewport);
      this.footer = new Footer();
      this.footer.render(this.$viewport);
    }

    BookmarksBar = (function() {
      function BookmarksBar() {
        var _this = this;
        this.bookmarksLoaded = new RSVP.Promise(function(resolve, reject) {
          return chrome.bookmarks.getChildren("1", function(bookmarks) {
            _this.bookmarks = bookmarks;
            return resolve(_this.bookmarks);
          });
        });
      }

      BookmarksBar.prototype.render = function($viewport) {
        var _this = this;
        this.$viewport = $viewport;
        this.$el = document.createElement("div");
        this.$el.id = "bookmarks-bar";
        this.$viewport.appendChild(this.$el);
        return this.bookmarksLoaded.then(function() {
          var bookmarksList, otherBookmarksList;
          bookmarksList = new BookmarksList(_this.bookmarks);
          bookmarksList.render(_this.$el);
          otherBookmarksList = new BookmarksList([
            {
              id: "2",
              title: "Other Bookmarks"
            }
          ]);
          otherBookmarksList.render(_this.$el);
          return otherBookmarksList.$el.className += " other-bookmarks";
        });
      };

      return BookmarksBar;

    })();

    BookmarksList = (function() {
      function BookmarksList() {
        _ref = _class.apply(this, arguments);
        return _ref;
      }

      _class = (function(bookmarks) {
        this.bookmarks = bookmarks;
      });

      BookmarksList.prototype.render = function($viewport) {
        var bookmark, bookmarkItem, _i, _len, _ref1;
        this.$viewport = $viewport;
        this.$el = document.createElement("ul");
        this.$el.className = "bookmarks-list clearfix";
        _ref1 = this.bookmarks;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          bookmark = _ref1[_i];
          bookmarkItem = new BookmarkItem(bookmark);
          bookmarkItem.delegate = this;
          bookmarkItem.render(this.$el);
        }
        return this.$viewport.appendChild(this.$el);
      };

      BookmarksList.prototype.BookmarkItemDidClickFolder = function(bookmarkItem) {
        var _this = this;
        return chrome.bookmarks.getChildren(bookmarkItem.bookmark.id, function(bookmarks) {
          if (_this.popup) {
            _this.popup.hide();
            _this.popup = null;
          }
          _this.popup = new BookmarksPopup(bookmarks, {
            parentPopup: null
          });
          return _this.popup.render(bookmarkItem.$link);
        });
      };

      return BookmarksList;

    })();

    BookmarksPopup = (function() {
      function BookmarksPopup(bookmarks, options, flowtipOptions) {
        this.bookmarks = bookmarks;
        this.options = options != null ? options : {};
        this.flowtipOptions = flowtipOptions != null ? flowtipOptions : {};
        this.parentPopup = this.options.parentPopup;
      }

      BookmarksPopup.prototype.render = function($target) {
        var bookmark, bookmarkItem, flowtipOptions, _i, _len, _ref1;
        this.$target = $target;
        this.$el = document.createElement("ul");
        this.$el.className = "bookmarks-list";
        _ref1 = this.bookmarks;
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          bookmark = _ref1[_i];
          bookmarkItem = new BookmarkItem(bookmark);
          bookmarkItem.delegate = this;
          bookmarkItem.render(this.$el);
        }
        flowtipOptions = this.parentPopup ? {
          region: "right",
          topDisabled: true,
          leftDisabled: false,
          rightDisabled: false,
          bottomDisabled: true,
          rootAlign: "edge",
          leftRootAlignOffset: 0,
          rightRootAlignOffset: -0.1,
          targetAlign: "edge",
          leftTargetAlignOffset: 0,
          rightTargetAlignOffset: -0.1
        } : {
          region: "bottom",
          topDisabled: true,
          leftDisabled: true,
          rightDisabled: true,
          bottomDisabled: false,
          rootAlign: "edge",
          rootAlignOffset: 0,
          targetAlign: "edge",
          targetAlignOffset: 0
        };
        this.flowtip = new FlowTip(_.extend({
          className: "bookmarks-popup",
          hasTail: false,
          rotationOffset: 0,
          edgeOffset: 10,
          targetOffset: 2,
          maxHeight: "" + (this.maxHeight()) + "px"
        }, flowtipOptions, this.flowtipOptions));
        this.flowtip.setTooltipContent(this.$el);
        this.flowtip.setTarget(this.$target);
        return this.flowtip.show();
      };

      BookmarksPopup.prototype.hide = function() {
        if (this.popup) {
          this.popup.hide();
          this.popup = null;
        }
        this.flowtip.hide();
        return this.flowtip.destroy();
      };

      BookmarksPopup.prototype.maxHeight = function() {
        return 300;
      };

      BookmarksPopup.prototype.BookmarkItemDidClickFolder = function(bookmarkItem) {
        var _this = this;
        return chrome.bookmarks.getChildren(bookmarkItem.bookmark.id, function(bookmarks) {
          if (_this.popup) {
            _this.popup.hide();
            _this.popup = null;
          }
          _this.popup = new BookmarksPopup(bookmarks, {
            parentPopup: _this
          });
          return _this.popup.render(bookmarkItem.$link);
        });
      };

      return BookmarksPopup;

    })();

    BookmarkItem = (function() {
      function BookmarkItem() {
        _ref1 = _class1.apply(this, arguments);
        return _ref1;
      }

      _class1 = (function(bookmark) {
        this.bookmark = bookmark;
      });

      BookmarkItem.prototype.render = function($viewport) {
        var $icon, $label, $link,
          _this = this;
        this.$viewport = $viewport;
        this.$el = document.createElement("li");
        this.$el.className = "bookmark-item";
        if (!this.bookmark.url) {
          this.$el.className += " folder-item";
        }
        $link = document.createElement("a");
        $icon = document.createElement("img");
        $label = document.createElement("span");
        $link.className = "clearfix";
        if (this.bookmark.url) {
          $link.setAttribute("href", this.bookmark.url);
        } else {
          $link.addEventListener("click", function() {
            var _ref2;
            return (_ref2 = _this.delegate) != null ? typeof _ref2.BookmarkItemDidClickFolder === "function" ? _ref2.BookmarkItemDidClickFolder(_this) : void 0 : void 0;
          }, false);
        }
        $icon.setAttribute("src", this.faviconURL());
        $icon.setAttribute("width", "16");
        $icon.setAttribute("height", "16");
        $label.innerHTML = this.bookmark.title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        $link.appendChild($icon);
        $link.appendChild($label);
        this.$el.appendChild($link);
        this.$link = $link;
        return this.$viewport.appendChild(this.$el);
      };

      BookmarkItem.prototype.faviconURL = function() {
        if (this.bookmark.url) {
          return "chrome://favicon/" + this.bookmark.url;
        } else {
          return "images/folder.png";
        }
      };

      return BookmarkItem;

    })();

    AppsList = (function() {
      function AppsList() {
        var _this = this;
        this.appsLoaded = new RSVP.Promise(function(resolve, reject) {
          return chrome.management.getAll(function(extensions) {
            var extension;
            _this.apps = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = extensions.length; _i < _len; _i++) {
                extension = extensions[_i];
                if (extension.enabled && extension.isApp) {
                  _results.push(extension);
                }
              }
              return _results;
            })();
            return resolve(_this.apps);
          });
        });
        window.addEventListener("resize", function() {
          return _this.repositionList();
        });
      }

      AppsList.prototype.render = function(viewport) {
        var _this = this;
        this.viewport = viewport;
        this.el = document.createElement("div");
        this.el.id = "apps-wrapper";
        this.list = document.createElement("ul");
        this.list.id = "apps";
        this.list.className = "clearfix";
        this.el.appendChild(this.list);
        this.viewport.appendChild(this.el);
        return this.appsLoaded.then(function() {
          _this.renderApps();
          return _this.repositionList();
        });
      };

      AppsList.prototype.renderApps = function() {
        var app, appItem, _i, _len, _ref2, _results;
        this.apps.unshift({
          name: "Store",
          url: "https://chrome.google.com/webstore",
          icons: [
            {
              size: 128,
              url: "images/web-store_128.png"
            }
          ]
        });
        _ref2 = this.apps;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          app = _ref2[_i];
          appItem = new AppItem(app);
          _results.push(appItem.render(this.list));
        }
        return _results;
      };

      AppsList.prototype.repositionList = function() {
        return this.list.style.marginTop = ((this.el.clientHeight - this.list.clientHeight) / 3) + "px";
      };

      return AppsList;

    })();

    AppItem = (function() {
      function AppItem() {
        _ref2 = _class2.apply(this, arguments);
        return _ref2;
      }

      _class2 = (function(app) {
        this.app = app;
      });

      AppItem.prototype.render = function(viewport) {
        var icon, label, link,
          _this = this;
        this.viewport = viewport;
        this.el = document.createElement("li");
        this.el.className = "app-item";
        link = document.createElement("a");
        icon = document.createElement("img");
        label = document.createElement("span");
        link.className = "clearfix";
        if (this.app.id) {
          link.addEventListener("click", function() {
            return chrome.management.launchApp(_this.app.id, function() {
              return window.close();
            });
          }, false);
        } else if (this.app.url) {
          link.setAttribute("href", this.app.url);
        }
        icon.setAttribute("src", this.iconURL());
        icon.setAttribute("width", "128");
        icon.setAttribute("height", "128");
        label.innerHTML = this.app.name.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        link.appendChild(icon);
        link.appendChild(label);
        this.el.appendChild(link);
        return this.viewport.appendChild(this.el);
      };

      AppItem.prototype.iconURL = function() {
        var icon, largestURL, size, _i, _len, _ref3;
        size = 0;
        largestURL = null;
        _ref3 = this.app.icons;
        for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
          icon = _ref3[_i];
          if (icon.size > size) {
            size = icon.size;
            largestURL = icon.url;
          }
        }
        return largestURL;
      };

      return AppItem;

    })();

    Footer = (function() {
      function Footer() {}

      Footer.prototype.render = function($viewport) {
        var img, storeLink, storeLogo, storeTitle, title;
        this.$viewport = $viewport;
        this.el = document.createElement("div");
        this.el.id = "footer";
        img = document.createElement("img");
        img.className = "chrome-logo";
        img.setAttribute("src", "images/chrome.png");
        img.setAttribute("width", "28");
        img.setAttribute("height", "28");
        this.el.appendChild(img);
        title = document.createElement("h1");
        title.innerHTML = "chrome";
        this.el.appendChild(title);
        storeLink = document.createElement("a");
        storeLink.className = "web-store";
        storeLink.setAttribute("href", "https://chrome.google.com/webstore");
        storeTitle = document.createElement("span");
        storeTitle.innerHTML = "Web Store";
        storeLink.appendChild(storeTitle);
        storeLogo = document.createElement("img");
        storeLogo.setAttribute("src", "images/web-store_20.png");
        storeLogo.setAttribute("width", "20");
        storeLogo.setAttribute("height", "20");
        storeLink.appendChild(storeLogo);
        this.el.appendChild(storeLink);
        return this.$viewport.appendChild(this.el);
      };

      return Footer;

    })();

    return ChromeClassicNewTab;

  })();

  window.onload = function() {
    var classicNewTab;
    return classicNewTab = new ChromeClassicNewTab(document.body);
  };

}).call(this);
