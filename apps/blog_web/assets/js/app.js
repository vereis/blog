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
    }
  }
});

import hljs from "highlight.js/lib/core";
import hljsBash from "highlight.js/lib/languages/bash";
import hljsElixir from "highlight.js/lib/languages/elixir";
import hljsNix from "highlight.js/lib/languages/nix";
import hljsSql from "highlight.js/lib/languages/sql";

hljs.registerLanguage("bash", hljsBash);
hljs.registerLanguage("elixir", hljsElixir);
hljs.registerLanguage("nix", hljsNix);
hljs.registerLanguage("sql", hljsSql);

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
