const repo = "Defelo/nixpkgs-review-gha";

const sleep = duration => new Promise(resolve => setTimeout(resolve, duration));
const query = async (doc, sel) => {
  while (true) {
    const elem = doc.querySelector(sel);
    if (elem !== null) return elem;
    await sleep(100);
  }
};

const setup = async () => {
  const match = /^https:\/\/github.com\/nixos\/nixpkgs\/pull\/(\d+)/i.exec(location.href);
  if (match === null) return;
  
  const pr = match[1];
  const actions = await query(document, ".gh-header-show .gh-header-actions");

  if (actions.querySelector(".run-nixpkgs-review") === null) {
    const btn = document.createElement("button");
    btn.classList.add("Button", "Button--secondary", "Button--small", "run-nixpkgs-review");
    btn.innerText = "Run nixpkgs-review";
    actions.prepend(btn);
    btn.onclick = () => {
      const w = window.open(`https://github.com/${repo}/actions/workflows/review.yml`);
      w.addEventListener("load", async () => {
        (await query(w.document, "details > summary.btn")).click();
        (await query(w.document, "input.form-control[name='inputs[pr]']")).value = pr;
      });
    };
  }

  if (actions.querySelector(".goto-pr-tracker") === null) {
    const btn = document.createElement("button");
    btn.classList.add("Button", "Button--secondary", "Button--small", "goto-pr-tracker");
    btn.innerText = "PR Tracker";
    actions.prepend(btn);
    btn.onclick = () => {
      // window.open(`https://nixpk.gs/pr-tracker.html?pr=${pr}`);
      window.open(`https://nixpkgs-tracker.ocfox.me/?pr=${pr}`);
    };
  }
}

navigation.addEventListener('navigate', setup);
setup();
