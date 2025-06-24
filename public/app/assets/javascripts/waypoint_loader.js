(function(exports) {
    var BATCH_SIZE = 2;
    var SCROLL_DELAY_MS = 50;
    var SCROLL_DRAG_DELAY_MS = 500;
    var LOAD_THRESHOLD_PX = 5000;

    var HASH_PREFIX = 'scroll::';

    function WaypointLoader(base_url, elt, recordCount, waypoint_loaded_callback, done_callback) {
        this.base_url = base_url;
        this.wrapper = elt;
        this.elt = elt.find('.infinite-record-container');
        this.contextSummaryElt = elt.siblings('.infinite-record-context');
        this.container = elt.closest('.feed-container');
        this.recordCount = recordCount;

        this.nextScrollAllowedTime = 0;

        var self = this;

        function onDone() {
            if (done_callback) {
                done_callback();
            }

            self.handleHashOnLoad();
            self.updateContextSummary();
        }

        function onLoaded() {
            if (waypoint_loaded_callback) {
                waypoint_loaded_callback();
            }
        }

        this.initKeyboardNavigation();
        // this.populateWaypoints(onLoaded, onDone);
        this.considerPopulatingWaypoints(false, null, onLoaded);
        this.initEventHandlers();
    }

    WaypointLoader.prototype.findClosestElement = function (elements) {
        var self = this;

        if (elements.length <= 1) {
            return 0;
        }

        var containerTop = self.wrapper.offset().top;
        var closestTop = elements.first().offset().top - containerTop;

        var startSearch = 0;
        var endSearch = elements.length - 1;

        var topOf = function (elt) {
            return elt.getBoundingClientRect().top - containerTop;
        };

        if (topOf(elements[startSearch]) <= 0 && topOf(elements[endSearch]) <= 0) {
            /* We're at the end */
            return endSearch;
        }

        while (
            startSearch + 1 < endSearch &&
                topOf(elements[startSearch]) < 0 &&
                topOf(elements[endSearch]) > 0
        ) {
            var midIdx = Math.floor((endSearch - startSearch) / 2) + startSearch;

            var midElement = elements[midIdx];
            var midElementTop = topOf(midElement);

            if (midElementTop > 0) {
                endSearch = midIdx;
            } else if (midElementTop <= 0) {
                startSearch = midIdx;
            }
        }

        if (
            Math.abs(topOf(elements[startSearch])) <
            Math.abs(topOf(elements[endSearch]))
        ) {
            return startSearch;
        } else {
            return endSearch;
        }
    };

    var populateRunning = false;

    WaypointLoader.prototype.considerPopulatingWaypoints = function (
        preserveScroll,
        reentrant,
        done_callback
    ) {
        var self = this;

        if (!done_callback) {
            done_callback = $.noop;
        }

        if (populateRunning && !reentrant) {
            return;
        }

        populateRunning = true;

        var waypoints = self.elt.find('.waypoint:not(.populated)');
        var closestIdx = self.findClosestElement(waypoints);
        var containerTop = self.wrapper.offset().top;

        if (
            waypoints.length > 0 &&
                Math.abs(
                    waypoints[closestIdx].getBoundingClientRect().top - containerTop
                ) < LOAD_THRESHOLD_PX
        ) {
            var start = Math.max(closestIdx - BATCH_SIZE / 2, 0);
            var end = start + BATCH_SIZE;

            self.populateWaypoints(
                waypoints.slice(start, end),
                preserveScroll,
                function () {
                    done_callback();
                    populateRunning = false;
                    // self.considerPopulatingWaypoints(preserveScroll, true, done_callback);
                }
            );
        } else {
            done_callback();
            populateRunning = false;
        }
    };

    WaypointLoader.prototype.populateWaypoints = function (
        waypointElts,
        preserveScroll,
        done_callback
    ) {
        var self = this;

        if (!done_callback) {
            done_callback = $.noop;
        }

        var populated_count = 0;

        $(waypointElts).each(function (_, waypoint) {
            if (waypoint.classList.contains('populated')) {
                populated_count++;

                if (waypointElts.length <= populated_count) {
                    done_callback();
                }

                return true;
            }

            waypoint.classList.add('populated');

            var waypointNumber = $(waypoint).data('waypoint-number');
            var waypointSize = $(waypoint).data('waypoint-size');
            var collectionSize = $(waypoint).data('collection-size');
            var uris = $(waypoint).data('uris').split(';');

            self.elt.attr('aria-busy', 'true');

            self.contextSummaryElt.find('.waypoint-loading-spinner').show();

            $.ajax(self.url_for('waypoints.json'), {
                method: 'GET',
                data: {
                    urls: uris,
                    number: waypointNumber,
                    size: waypointSize,
                    collection_size: collectionSize,
                },
            }).done(function (records) {
                const recordsToAppend = $('<div />');

                $(uris).each(function (i, uri) {
                    if (records[uri]) {
                        recordNumber = waypointNumber * waypointSize + i;
                        recordsToAppend.append(
                            $('<div class="infinite-record-record" />')
                                .attr('id', 'record-number-' + recordNumber)
                                .data('record-number', recordNumber)
                                .data('uri', uri)
                                .html(records[uri])
                        );
                    }
                });

                self.nextScrollAllowedTime = new Date().getTime() + 200;
                $(waypoint).append(recordsToAppend.children());

                if (preserveScroll) {
                    $(waypoint)[0].scrollIntoView();
                }

                populated_count += 1;

                if (waypointElts.length <= populated_count) {
                    done_callback();
                }

                $(waypoint).trigger('waypointloaded');
                self.elt.removeAttr('aria-busy');
                self.contextSummaryElt.find('.waypoint-loading-spinner').hide();
            });
        });
    };


    WaypointLoader.prototype.url_for = function (action) {
        var self = this;

        return self.base_url + '/' + action;
    };


    WaypointLoader.prototype.getClosestElement = function(prioritiseFocused) {
        if (prioritiseFocused && this.elt.find('.infinite-item:focus').length == 1) {
            return this.elt.find('.infinite-item:focus').closest('.infinite-record-record');
        } else {
            var allRecords = this.elt.find('.infinite-record-record');
            var index = this.findClosestElement(allRecords);

            return $(allRecords.get(index));
        }
    };

    WaypointLoader.prototype.getCurrentContext = function(prioritiseFocused) {
        var current = this.getClosestElement(prioritiseFocused);
        var ancestors = current.data('ancestors') || [];

        if (ancestors.length == 1) {
            if ($.inArray(current.data('level'), ["series", "collection"]) >= 0) {
                return current.data('uri');
            }
        }

        if (ancestors.length > 1) {
            for (var i=0; i<ancestors.length;i++) {
                if ($.inArray(ancestors[i]["level"], ["series", "collection"]) >= 0) {
                    return ancestors[i]["ref"];
                }
            }
        }

        return null;
    };

    WaypointLoader.prototype.updateContextSummary = function(prioritiseFocused) {
        var context = this.getCurrentContext(prioritiseFocused);
        if (context) {
            var $linkForContext = this.contextSummaryElt.find('.dropdown-menu a[data-uri="'+context+'"]');

            if ($linkForContext.length > 0) {
                $('#scrollContext .current-record-title').html($linkForContext.html());
                this.contextSummaryElt.find('.dropdown-menu a').removeAttr('aria-current');
                $linkForContext.attr('aria-current', 'true');
                $('#scrollContext').attr('title', $('#scrollContext .current-record-title').text().trim());
                return;
            }
        } else {
            var current = this.getClosestElement(prioritiseFocused);
            if (current && current.find('.infinite-item.infinite-item-resource').length > 0) {
                $('#scrollContext .current-record-title').html($('#scrollContext').parent().find('.dropdown-menu a:first').html());
                this.contextSummaryElt.find('.dropdown-menu a').removeAttr('aria-current');
                this.contextSummaryElt.find('.dropdown-menu a:first').attr('aria-current', 'true');
                $('#scrollContext').attr('title', $('#scrollContext .current-record-title').text().trim());
            } else {
                // do nothing
                return;
            }
        }
    };

    WaypointLoader.prototype.scrollToRecord = function (recordNumber) {
        var self = this;

        var waypointSize = $('.waypoint').first().data('waypoint-size');
        var targetWaypoint = Math.floor((recordNumber - 1) / waypointSize);

        var scrollTo = function (recordNumber) {
            $('#record-number-' + recordNumber + ' > .infinite-item')[0].scrollIntoView({block: recordNumber === 0 ? 'start' : 'center'});
            $('#record-number-' + recordNumber + ' > .infinite-item').focus();
        };

        if (recordNumber === 0) {
            // the resource!
            scrollTo(recordNumber);
        } else if (!$($('.waypoint')[targetWaypoint]).is('.populated')) {
            console.warn("Cannot scrollToRecord as waypoint not populated")
        } else if ($($('.waypoint')[targetWaypoint]).is('.loading')) {
            $($('.waypoint')[targetWaypoint]).focus();
            $($('.waypoint')[targetWaypoint]).on('waypointloaded', function() {
                scrollTo(recordNumber);
            });
        } else {
            scrollTo(recordNumber);
        }
    };

    WaypointLoader.prototype.scrollToRecordForURI = function(uri) {
        var self = this;

        if (uri.indexOf('/resources/') > 0) {
            self.scrollToRecord(0);
        } else {
            var $waypoint = self.wrapper.find('[data-uris*="'+uri+';"], [data-uris$="'+uri+'"]');

            if ($waypoint.length == 0) {
                // Record not found
                return;
            }

            const surroundingWaypoints = $waypoint.prevAll('.waypoint').slice(0, 1).add($waypoint).add($waypoint.nextAll('.waypoint').slice(0, 2));

            self.nextScrollAllowedTime = new Date().getTime() + 2000;

            this.populateWaypoints(surroundingWaypoints, false, function () {
                setTimeout(function () {
                    self.wrapper.find(".infinite-item[data-uri='" + uri + "']")[0].focus();
                    self.wrapper.find(".infinite-item[data-uri='" + uri + "']")[0].parentNode.scrollIntoView({block: 'center'});
                    self.updateContextSummary();
                }, 200);
            });
        }

        self.updateHash(uri);
    };

    WaypointLoader.prototype.updateHash = function(uri) {
        history.replaceState(null, null, document.location.pathname + '#' + HASH_PREFIX + uri);
    };

    WaypointLoader.prototype.handleHashOnLoad = function() {
        var self = this;

        if (!location.hash) {
            return;
        }

        if (location.hash.startsWith('#'+HASH_PREFIX)) {
            var regex = new RegExp("^#("+HASH_PREFIX+")");
            var uri = location.hash.replace(regex, "");

            setTimeout(function() {
                self.scrollToRecordForURI(uri);
            });
        }
    };

    WaypointLoader.prototype.initEventHandlers = function () {
        var self = this;
        self.container.on('click', '.infinite-record-context .dropdown-menu a', function() {
            $('#scrollContext').dropdown('toggle')
            self.scrollToRecordForURI($(this).data('uri'));
        });

        self.container.on('focus', '.infinite-item', function() {
            var $item = $(this);
            // ensure scroll has finished post-focus 
            setTimeout(function() {
                self.updateHash($item.data('uri'));
                self.updateContextSummary(true);
            })
        });

        var scrollTimer = undefined;

        $(window).on('scroll', function() {
            if (window.scrollY > self.elt.offset().top) {
                self.contextSummaryElt.addClass('fixed');
                self.contextSummaryElt.find('.infinite-record-context-selector').css('width', self.elt.width() + 'px').css('margin-left', self.elt.offset().left + 'px');
                self.contextSummaryElt.find('.infinite-record-context-resource').css('padding-left', self.elt.offset().left + 'px');
            } else {
                self.contextSummaryElt.removeClass('fixed').find('.infinite-record-context-selector').css('width', 'auto').css('margin-left', 0);
            }

            self.updateContextSummary();

            if (scrollTimer) {
                clearInterval(scrollTimer);
            }

            scrollTimer = setTimeout(function () {
                if (new Date().getTime() > self.nextScrollAllowedTime) {
                    self.considerPopulatingWaypoints(true);
                }
            }, SCROLL_DELAY_MS);
        });

    }

    WaypointLoader.prototype.initKeyboardNavigation = function() {
        var self = this;

        self.elt.on('keydown', '.infinite-record-record', function(event) {
            var $item = $(this).closest('.infinite-record-record');

            var focusRecordNumber = $item.find(' > .infinite-item').data('recordnumber');
            var firstRecordNumber = 0;
            var lastRecordNumber = $item.find(' > .infinite-item').data('collectionsize') - 1;

            if (event.keyCode == 34) { // page down
                // focus next feed article
                focusRecordNumber = Math.min(focusRecordNumber + 1, lastRecordNumber);
            } else if (event.keyCode == 33) { // page up
                // focus previous feed article
                if ($item.prev()) {
                    focusRecordNumber = Math.max(focusRecordNumber - 1, firstRecordNumber);
                }
            } else if (event.ctrlKey && event.keyCode == 35) { // control + end
                // jump to bottom
                focusRecordNumber = lastRecordNumber;
            } else if (event.ctrlKey && event.keyCode == 36) { // control + home
                // jump to top
                focusRecordNumber = firstRecordNumber;
            } else {
                return true;
            }

            event.preventDefault();

            self.scrollToRecord(focusRecordNumber);

            return false;
        });
    };

    WaypointLoader.prototype.findClosestElement = function (elements) {
        var self = this;

        if (elements.length <= 1) {
            return 0;
        }

        var containerTop = window.scrollY;
        var closestTop = elements.first().offset().top;

        var startSearch = 0;
        var endSearch = elements.length - 1;

        var topOf = function (elt) {
            return elt.getBoundingClientRect().top;
        }

        if (topOf(elements[startSearch]) <= 0 && topOf(elements[endSearch]) <= 0) {
            /* We're at the end */
            return endSearch;
        }

        while ((startSearch + 1) < endSearch && topOf(elements[startSearch]) < 0 && topOf(elements[endSearch]) > 0) {
            var midIdx = Math.floor(((endSearch - startSearch) / 2)) + startSearch;

            var midElement = elements[midIdx]
            var midElementTop = topOf(midElement);

            if (midElementTop > 0) {
                endSearch = midIdx;
            } else if (midElementTop <= 0) {
                startSearch = midIdx;
            }
        }

        if (Math.abs(topOf(elements[startSearch])) < Math.abs(topOf(elements[endSearch]))) {
            return startSearch;
        } else {
            return endSearch;
        }
    };

    exports.WaypointLoader = WaypointLoader;

}(window));
