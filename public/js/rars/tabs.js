"use strict";

class Tabs {
    static load() {
        document.querySelectorAll(".tabs").forEach( (tabStrip) => {
            tabStrip.querySelectorAll(".tab > a, .tab > button").forEach( (tabButton) => {
                tabButton.addEventListener("click", (event) => {
                    tabStrip.querySelectorAll(".tab").forEach( (tab) => {
                        tab.classList.remove("active");
                    });
                    tabButton.parentNode.classList.add("active");

                    var tabPanels = tabStrip.nextElementSibling;
                    if (tabPanels) {
                        tabPanels.querySelectorAll(":scope > .tab-panel").forEach( (tabPanel) => {
                            tabPanel.classList.remove("active");
                        });
                    }

                    var tabPanel = document.querySelector(".tab-panel#" + tabButton.getAttribute('aria-controls'));
                    if (tabPanel) {
                        tabPanel.classList.add("active");
                    }

                    event.stopPropagation();
                    event.preventDefault();
                });
            });
        });
    }
}

export default Tabs;
