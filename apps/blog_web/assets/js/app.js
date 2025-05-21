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
      highlightAll()();
      dataHrefAll()();
      initCrtFilter();
    }
  }
});

import hljs from "highlight.js/lib/core";
import hljsBash from "highlight.js/lib/languages/bash";
import hljsElixir from "highlight.js/lib/languages/elixir";
import hljsErlang from "highlight.js/lib/languages/erlang";
import hljsNix from "highlight.js/lib/languages/nix";
import hljsJs from "highlight.js/lib/languages/javascript";
import hljsSql from "highlight.js/lib/languages/sql";
import hljsGql from "highlight.js/lib/languages/graphql";

hljs.registerLanguage("bash", hljsBash);
hljs.registerLanguage("elixir", hljsElixir);
hljs.registerLanguage("erlang", hljsErlang);
hljs.registerLanguage("nix", hljsNix);
hljs.registerLanguage("js", hljsJs);
hljs.registerLanguage("sql", hljsSql);
hljs.registerLanguage("graphql", hljsGql);

const highlightAll = () => {
  let timer;

  return (...args) => {
    clearTimeout(timer);

    timer = setTimeout(() => {
      document.querySelectorAll("pre code[data-highlighted]").forEach((code) => {
        code.dataset.highlighted = false;
      });

      hljs.highlightAll()

      document.querySelectorAll("pre code[data-highlighted]").forEach((code) => {
        const lang = code.classList?.[0]
        if (lang) {
          code.parentNode.setAttribute("data-lang", lang)
        }
      })
    }, 100)
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

// Highlight all code blocks on page load and live navigation
window.addEventListener("phx:page-loading-stop", (_info) => highlightAll()());
window.addEventListener("phx:page-loading-stop", (_info) => highlightAll()());
window.addEventListener("phx:navigate", (_info) => highlightAll()());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;


const initCrtFilter = () => {
  let enabled = localStorage.crtFilter === "true";

  // If we've not got a persisted preference, set it
  if (localStorage.crtFilter === undefined) {
    console.log("shouldn't be here")
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
