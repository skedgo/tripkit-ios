// Keyboard navigation
document.addEventListener("keydown", function (e) {
  // Skip if user is typing in an input/textarea
  const tag = e.target.tagName.toLowerCase();
  if (tag === "input" || tag === "textarea") return;

  let page = null;

  switch (e.key) {
    case "ArrowRight":
      page = findNavLink("next");
      break;
    case "ArrowLeft":
      page = findNavLink("prev");
      break;
  }

  if (page) {
    window.location.href = page;
  }
});

// Helper to find navigation link by text
function findNavLink(rel) {
  const link = document.querySelector(`a[rel="${rel}"]`);
  return link ? link.getAttribute("href") : null;
}

let isSearchVisible = false;
let isMenuVisible = false;

function toggleSearch() {
  const el = document.getElementById("mkdocs_search_modal");
  el.classList.toggle("opacity-0");
  el.classList.toggle("pointer-events-none");
  el.classList.toggle("backdrop-blur-xs");
  document.body.classList.toggle("overflow-hidden");

  if (!isSearchVisible) {
    const input = document.getElementById("mkdocs-search-query");
    input.focus();
  }
  isSearchVisible = !isSearchVisible;
}

document.addEventListener("keydown", (event) => {
  const isMac = navigator.platform.toUpperCase().indexOf("MAC") >= 0;
  const isCmdK = isMac
    ? event.metaKey && event.key === "k"
    : event.ctrlKey && event.key === "k";

  if (isCmdK) {
    event.preventDefault(); // prevent browser default (like "search in page")
    toggleSearch();
  }

  if (event.key === "Escape" && isSearchVisible) {
    toggleSearch(); // hide on Esc
  }
});

function toggleMenu() {
  const menu = document.getElementById("menu-mobile");
  const header = document.getElementById("site-header");
  const overlay = document.getElementById("menu-overlay");
  const viewportHeight = window.innerHeight;
  const headerHeight = header.offsetHeight;
  const startHeight = menu.offsetHeight;
  const menuHeight = menu.scrollHeight;
  const endHeight = Math.min(menuHeight, viewportHeight - headerHeight);
  menu.classList.toggle("max-h-0");
  menu.classList.toggle("opacity-0");
  menu.classList.toggle("-translate-y-4");
  menu.classList.toggle("opacity-100");

  // Animate overlay opacity
  overlay.classList.toggle("opacity-0");
  overlay.classList.toggle("opacity-100");
  overlay.classList.toggle("pointer-events-none");

  menu.animate(
    [
      { maxHeight: `${startHeight}px` },
      { maxHeight: isMenuVisible ? "0px" : `${endHeight}px` },
    ],
    {
      duration: 300,
      easing: "ease",
      fill: "forwards",
    },
  );

  isMenuVisible = !isMenuVisible;
}

function initSidebar() {
  const headings = document.querySelectorAll("h2"); // or whatever heading levels you want
  const tocLinks = document.querySelectorAll("#toc a"); // your TOC links

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return; // only care about *entering* headings
        const top = entry.boundingClientRect.top;

        // Only trigger when the heading enters near the top
        if (top >= 0 && top <= window.innerHeight * 0.3) {
          const id = entry.target.id;

          // Remove all active states
          tocLinks.forEach((link) => link.classList.remove("active"));

          // Add active to the current heading's TOC link
          const current = document.querySelector(`#toc a[href="#${id}"]`);
          if (current) current.classList.add("active");
        }
      });
    },
    {
      rootMargin: "-56px 0px -70% 0px",
      threshold: 0,
    },
  );

  // Observe all headings
  headings.forEach((h) => observer.observe(h));
}

document.addEventListener("DOMContentLoaded", initSidebar);
