(function() {

  var bookmarksList = document.getElementById("bookmarks");
  var otherBookmarksList = document.getElementById("other-bookmarks");
  var othersLink = document.getElementById("others");
  var appsWrapper = document.getElementById("apps-wrapper");
  var appsList = document.getElementById("apps");

  var favicon = function(url) {
    return "chrome://favicon/" + url;
  };

  var appIcon = function(icons) {
    var size = 0;
    var url = null;
    var i; for (i = 0; i < icons.length; i++) {
      var icon = icons[i];
      if (icon.size > size) {
        size = icon.size;
        url = icon.url;
      }
    }
    return url;
  };

  var bookmarkItem = function(bookmark) {
    var item = document.createElement("li");
    var link = document.createElement("a");
    var icon = document.createElement("img");
    var label = document.createElement("span");

    link.className = "clearfix";
    link.setAttribute("href", bookmark.url);

    icon.setAttribute("src", favicon(bookmark.url));
    icon.setAttribute("width", "16");
    icon.setAttribute("height", "16");

    label.innerHTML = bookmark.title.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

    link.appendChild(icon);
    link.appendChild(label);
    item.appendChild(link);

    return item;
  };

  var populateBookmarksBar = function(bookmarks) {
    var i; for (i = 0; i < bookmarks.length; i++) {
      if (bookmarks[i].url) {
        bookmarksList.appendChild(bookmarkItem(bookmarks[i]));
      }
    }
  };

  var populateOtherBookmarks = function(bookmarks) {
    var i; for (i = 0; i < bookmarks.length; i++) {
      if (bookmarks[i].url) {
        otherBookmarksList.appendChild(bookmarkItem(bookmarks[i]));
      }
    }
  };

  var appItem = function(app) {
    var item = document.createElement("li");
    var link = document.createElement("a");
    var icon = document.createElement("img");
    var label = document.createElement("span");

    link.className = "clearfix";
    link.addEventListener('click', function() {
      chrome.management.launchApp(app.id, function() {
        window.close();
      });
    }, false);

    icon.setAttribute("src", appIcon(app.icons));
    icon.setAttribute("width", "128");
    icon.setAttribute("height", "128");

    label.innerHTML = app.name.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

    link.appendChild(icon);
    link.appendChild(label);
    item.appendChild(link);

    return item;
  };

  var populateApps = function(apps) {
    var i; for (i = 0; i < apps.length; i++) {
      appsList.appendChild(appItem(apps[i]));
    }
  };

  chrome.bookmarks.getChildren("1", function(bookmarks) {
    populateBookmarksBar(bookmarks);
  });

  othersLink.addEventListener('click', function() {
    chrome.bookmarks.getChildren("2", function(bookmarks) {
      populateOtherBookmarks(bookmarks);
    });
  }, false);

  chrome.management.getAll(function(extensions) {
    var apps = [];
    var i; for (i = 0; i < extensions.length; i++) {
      var extension = extensions[i];
      if (extension.enabled && extension.isApp) {
        apps.push(extension);
      }
    }
    populateApps(apps);
    onWindowResize();
  });

  var onWindowResize = function() {
    appsList.style.marginTop = ((appsWrapper.clientHeight - appsList.clientHeight) / 3) + "px";
  };

  window.onresize = onWindowResize;

}).call(this);
