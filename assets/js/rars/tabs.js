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

                        // Check if the tabPanel is PJAX loaded
                        if (!tabPanel.classList.contains("pjax-loaded")) {
                            var pjaxURL = tabPanel.getAttribute('data-pjax');
                            if (pjaxURL) {
                                // Fetch HTML page and get content at "body.documentation"
                                tabPanel.classList.add("pjax-loaded");
                                fetch(pjaxURL, {
                                    credentials: 'include'
                                }).then(function(response) {
                                    return response.text();
                                }).then(function(text) {
                                    // Push text to dummy node
                                    var dummy = document.createElement("div");
                                    dummy.setAttribute('hidden', '');
                                    dummy.innerHTML = text;
                                    document.body.appendChild(dummy);
                                    var innerElement = dummy.querySelector(".content.documentation");
                                    tabPanel.innerHTML = "";
                                    tabPanel.appendChild(innerElement);
                                    dummy.remove();
                                });
                            }
                        }
                    }

                    event.stopPropagation();
                    event.preventDefault();
                });
            });
        });
    }
}

export default Tabs;
