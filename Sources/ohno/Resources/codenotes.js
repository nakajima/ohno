document.addEventListener("click", function (event) {
  const target = event.target.closest(".code-note-button, .code-note-code");

  if (!target) {
    return;
  }

  const codeNoteID = target.getAttribute("href");
  if (codeNoteID) {
    event.preventDefault();
    const codeNote = document.querySelector(codeNoteID);
    if (codeNote.classList.contains("expanded")) {
      codeNote.classList.replace("expanded", "collapsed");
    } else if (codeNote.classList.contains("collapsed")) {
      codeNote.classList.replace("collapsed", "expanded");
    } else {
      codeNote.classList.add("expanded");
    }

    const container = target.closest(".code-note-container");
    const button = container.querySelector(".code-note-button");
    if (codeNote.classList.contains("expanded")) {
      button.textContent = "Hide";
    } else {
      button.textContent = "Show";
    }
  }
});
