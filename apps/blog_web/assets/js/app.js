// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// We need to import the CSS so that esbuild will bundle it
import "../css/app.css";

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  dom: {
    onBeforeElUpdated: (_) => {
      imgLinkAll()();
      dataHrefAll()();
      initCrtFilter();
      initScrollspy()();
    }
  }
});

const imgLinkAll = () => {
  let timer;

  return (...args) => {
    clearTimeout(timer);

    timer = setTimeout(() => {
      document.querySelectorAll("img[src]").forEach((el) => {
        el.onclick = () => {
          window.open(el.src, "_blank");
        }
      });
    }, 10);
  }
}

const dataHrefAll = () => {
  let timer;

  return (...args) => {
    clearTimeout(timer);

    timer = setTimeout(() => {
      document.querySelectorAll("a[href]").forEach((el) => {
        const url = new URL(el.href);
        const slugs = url.pathname.split("/").filter((s) => s !== "");

        if (url.hash !== "") {
          slugs.push(url.hash);
        }

        if (slugs.length >= 2) {
          let dataHref = "";

          switch (url.host) {
            case "localhost:4000":
              dataHref = `/posts/${slugs[slugs.length - 1]}`;
              break;

            case "audible.com":
            case "www.audible.com":
              // Grab the book title
              dataHref = `${url.origin}/../${slugs[slugs.length - 2].replace("-Audiobook", "")}`;
              break;

            case "github.com":
            case "www.github.com":
              // Always show user and repo
              dataHref = `${url.origin}/${slugs[0]}/${slugs[1]}/../${slugs[slugs.length - 1]}`;
              break;

            case "mariagefreres.com":
            case "www.mariagefreres.com":
              // Always show the product
              dataHref = `${url.origin}/../${slugs[slugs.length - 1].replace("-tea-by-the-weight.html", "")}`;
              break;

            default:
              dataHref = `${url.origin}/../${slugs[slugs.length - 1]}`;
              break;
          }

          if (dataHref.length < el.href.length) {
            el.setAttribute("data-href", dataHref.replace(/\.html$/, ""));
          }
        }
      })
    }, 10)
  }
}

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

let scrollspyObserver;

const initScrollspy = () => {
  let timer;

  return (...args) => {
    clearTimeout(timer);

    timer = setTimeout(() => {
      if (scrollspyObserver) {
        scrollspyObserver.disconnect();
      }

      const headings = document.querySelectorAll('main h1, main h2, main h3, main h4, main h5, main h6');
      const tocLinks = document.querySelectorAll('aside.table-of-contents-container a');

      if (headings.length === 0 || tocLinks.length === 0) return;

      scrollspyObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          const id = entry.target.id;
          const tocLink = document.querySelector(`aside.table-of-contents-container a[href="#${id}"]`);

          if (tocLink) {
            if (entry.isIntersecting) {
              tocLinks.forEach(link => link.classList.remove('active'));
              tocLink.classList.add('active');
            }
          }
        });
      }, {
        rootMargin: '0px 0px -85% 0px' // Trigger when heading is near top of viewport
      });

      headings.forEach(heading => {
        if (heading.id) {
          scrollspyObserver.observe(heading);
        }
      });
    }, 50);
  }
}

const initCrtFilter = () => {
  let enabled = localStorage.crtFilter === "true";

  // If we've not got a persisted preference, set it
  if (localStorage.crtFilter === undefined) {
    enabled = !window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    localStorage.setItem("crtFilter", enabled);
  }

  if (enabled) {
    crtFilter.checked = true;
    document.body.classList.add("crt-filter");
  } else {
    crtFilter.checked = false;
    document.body.classList.remove("crt-filter");
  }
}

const toggleCrtFilter = e => {
  const enabled = localStorage.crtFilter === "true";
  localStorage.setItem("crtFilter", !enabled);
  initCrtFilter();
  return e.preventDefault();
}

window.addEventListener("toggle-crt-filter", toggleCrtFilter, false);
