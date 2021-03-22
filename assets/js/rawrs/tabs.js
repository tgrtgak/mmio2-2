"use strict";

import EventComponent from './event_component';

class Tabs extends EventComponent {
    constructor(tabStrip) {
        super();

        tabStrip.querySelectorAll(".tab > a, .tab > button").forEach( (tabButton) => {
            tabButton.addEventListener("click", (event) => {
                tabStrip.querySelectorAll(".tab").forEach( (tab) => {
                    tab.classList.remove("active");
                });
                tabButton.parentNode.classList.add("active");

                this.trigger("change", tabButton);

                var tabPanels = tabStrip.nextElementSibling;
                if (tabPanels) {
                    tabPanels.querySelectorAll(":scope > .tab-panel").forEach( (tabPanel) => {
                        tabPanel.classList.remove("active");
                    });
                }

                var tabPanel = document.querySelector(".tab-panel#" + tabButton.getAttribute('aria-controls'));
                if (tabPanel) {
                    let rootpath = document.body.getAttribute('data-rootpath');
                    tabPanel.classList.add("active");
                    let url = tabButton.getAttribute('href');
                    if (tabButton.previousElementSibling) {
                        url = tabButton.previousElementSibling.getAttribute('href');
                    }
                    if (tabPanel.querySelector("li.tab.active > a:not(.ajax)")) {
                        url = tabPanel.querySelector("li.tab.active > a:not(.ajax)").getAttribute('href');
                    }
                    url = rootpath + url;

                    window.history.replaceState(window.history.start, "", url);

                    // Check if the tabPanel is PJAX loaded
                    if (!tabPanel.classList.contains("pjax-loaded")) {
                        var pjaxURL = tabPanel.getAttribute('data-pjax');
                        if (tabButton.parentNode.querySelector("a.ajax")) {
                            pjaxURL = tabButton.parentNode.querySelector("a.ajax").getAttribute('href');
                        }
                        if (pjaxURL) {
                            pjaxURL = rootpath + pjaxURL;
                            // Fetch HTML page and get content at "body"
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

                                window.history.replaceState(window.history.start, "", url);

                                if (tabPanel.querySelector("li.tab.active > a")) {
                                    url = tabPanel.querySelector("li.tab.active > a").getAttribute('href');
                                }
                                window.history.replaceState(window.history.start, "", url);
                            });
                        }
                    }
                }

                event.stopPropagation();
                event.preventDefault();
            });
        });
    }

    static load(tabStrip) {
        if (tabStrip) {
            if (!Tabs._loaded.has(tabStrip)) {
                Tabs._loaded.set(tabStrip, new Tabs(tabStrip));
            }
            return Tabs._loaded.get(tabStrip);
        }
        else {
            document.querySelectorAll(".tabs").forEach( (tabStrip) => {
                Tabs.load(tabStrip);
            });
        }
    }
}

Tabs._loaded = new WeakMap();

export default Tabs;
