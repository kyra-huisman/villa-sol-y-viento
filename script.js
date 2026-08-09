document.addEventListener("DOMContentLoaded", function () {
  var year = new Date().getFullYear();
  document.querySelectorAll(".year").forEach(function (el) {
    el.textContent = year;
  });

  initNavToggle();
  initRandomOrder();
  initFilters();
  initLightbox();

  function initNavToggle() {
    var toggle = document.querySelector(".nav-toggle");
    var nav = document.querySelector(".nav");
    if (!toggle || !nav) return;
    toggle.addEventListener("click", function () {
      var open = nav.classList.toggle("open");
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    });
    nav.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () {
        nav.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
      });
    });
  }

  function initRandomOrder() {
    var gallery = document.querySelector(".gallery.big");
    if (!gallery) return;
    var tiles = Array.prototype.slice.call(gallery.querySelectorAll(".tile"));
    var floorplans = tiles.filter(function (t) {
      return t.getAttribute("data-category") === "floorplans";
    });
    var rest = tiles.filter(function (t) {
      return t.getAttribute("data-category") !== "floorplans";
    });

    for (var i = rest.length - 1; i > 0; i--) {
      var j = Math.floor(Math.random() * (i + 1));
      var tmp = rest[i];
      rest[i] = rest[j];
      rest[j] = tmp;
    }

    rest.concat(floorplans).forEach(function (t) {
      gallery.appendChild(t);
    });
  }

  function initFilters() {
    var bar = document.querySelector(".filter-bar");
    if (!bar) return;
    var buttons = Array.prototype.slice.call(bar.querySelectorAll(".filter-btn"));
    var tiles = Array.prototype.slice.call(document.querySelectorAll(".gallery .tile"));
    buttons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        buttons.forEach(function (b) {
          b.classList.remove("active");
          b.setAttribute("aria-selected", "false");
        });
        btn.classList.add("active");
        btn.setAttribute("aria-selected", "true");
        var filter = btn.getAttribute("data-filter");
        tiles.forEach(function (tile) {
          var show = filter === "all" || tile.getAttribute("data-category") === filter;
          tile.classList.toggle("hidden", !show);
        });
      });
    });
  }

  function initLightbox() {
    var triggers = Array.prototype.slice.call(document.querySelectorAll(".js-zoom"));
    if (!triggers.length) return;

    var isDutch = (document.documentElement.lang || "").toLowerCase().indexOf("nl") === 0;
    var t9n = isDutch
      ? { close: "Sluiten", prev: "Vorige foto", next: "Volgende foto" }
      : { close: "Close", prev: "Previous photo", next: "Next photo" };

    var lb = document.createElement("div");
    lb.className = "lightbox";
    lb.setAttribute("role", "dialog");
    lb.setAttribute("aria-modal", "true");
    lb.innerHTML =
      '<button type="button" class="lb-btn lb-close" aria-label="' + t9n.close + '">' +
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg></button>' +
      '<button type="button" class="lb-btn lb-prev" aria-label="' + t9n.prev + '">' +
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg></button>' +
      '<button type="button" class="lb-btn lb-next" aria-label="' + t9n.next + '">' +
      '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 5l7 7-7 7"/></svg></button>' +
      '<div class="lb-stage"><img alt=""></div>' +
      '<div class="lb-bar"><span class="lb-caption"></span></div>';
    document.body.appendChild(lb);

    var lbImg = lb.querySelector("img");
    var lbCaption = lb.querySelector(".lb-caption");
    var activeList = [];
    var activeIndex = 0;

    function isVisible(el) {
      return el.offsetParent !== null;
    }

    function render() {
      var t = activeList[activeIndex];
      var img = t.querySelector("img");
      // data-full verwijst naar het origineel op volledige resolutie;
      // het raster toont alleen de kleine versie uit images/thumbs/
      var full = t.getAttribute("data-full") || img.src;
      var caption = t.getAttribute("data-caption") || img.alt || "";

      lbImg.src = full;
      lbImg.alt = caption;
      lbCaption.textContent = caption;
    }

    function openAt(trigger) {
      activeList = triggers.filter(isVisible);
      activeIndex = activeList.indexOf(trigger);
      if (activeIndex === -1) {
        activeList = [trigger];
        activeIndex = 0;
      }
      render();
      lb.classList.add("open");
      document.body.style.overflow = "hidden";
    }

    function close() {
      lb.classList.remove("open");
      lbImg.src = "";
      document.body.style.overflow = "";
    }

    function next() {
      activeIndex = (activeIndex + 1) % activeList.length;
      render();
    }

    function prev() {
      activeIndex = (activeIndex - 1 + activeList.length) % activeList.length;
      render();
    }

    triggers.forEach(function (t) {
      t.addEventListener("click", function () {
        openAt(t);
      });
    });
    lb.querySelector(".lb-close").addEventListener("click", close);
    lb.querySelector(".lb-next").addEventListener("click", next);
    lb.querySelector(".lb-prev").addEventListener("click", prev);
    lb.addEventListener("click", function (e) {
      if (e.target === lb) close();
    });
    document.addEventListener("keydown", function (e) {
      if (!lb.classList.contains("open")) return;
      if (e.key === "Escape") close();
      if (e.key === "ArrowRight") next();
      if (e.key === "ArrowLeft") prev();
    });
  }
});
