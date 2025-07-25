require 'spec_helper'
require 'rails_helper'

describe 'Collection Organization', js: true do
  before(:all) do
    @repo = create(:repo, repo_code: "collection_organization_test_#{Time.now.to_i}")
    set_repo(@repo)
    @resource = create(:resource,
      title: 'This is <emph render="italic">a mixed content</emph> title',
      publish: true
    )
    @ao1 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      title: 'This is <emph render="italic">another mixed content</emph> title',
      publish: true
    )
    @ao2 = create(:archival_object,
      resource: {'ref' => @resource.uri},
      title: 'This is not a mixed content title',
      publish: true
    )
    @ao3 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
    @ao4 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
    @ao5 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
    @ao6 = create(:archival_object, resource: {'ref' => @resource.uri}, publish: true)
    @do = create(:digital_object, publish: true)
    @doc = create(:digital_object_component, publish: true, digital_object: { ref: @do.uri })
    run_indexers
  end

  before(:each) do
    allow(AppConfig).to receive(:[]).and_call_original
  end

  def sidebar_left_coordinate
    sidebar = find('.infinite-tree-sidebar')
    page.evaluate_script('arguments[0].getBoundingClientRect().left', sidebar)
  end

  def sidebar_right_coordinate
    sidebar = find('.infinite-tree-sidebar')
    page.evaluate_script('arguments[0].getBoundingClientRect().right', sidebar)
  end

  def content_right_coordinate
    content = find('.resizable-content-pane')
    page.evaluate_script('arguments[0].getBoundingClientRect().right', content)
  end

  def content_left_coordinate
    content = find('.resizable-content-pane')
    page.evaluate_script('arguments[0].getBoundingClientRect().left', content)
  end

  describe 'Infinite Tree sidebar' do
    before(:all) do
      set_repo(@repo)

      121.times do |i| # 5 batches
        instance_variable_set("@ao#{i + 1}_of_ao3", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao3.uri},
          publish: true
        ))
      end

      61.times do |i| # 3 batches
        instance_variable_set("@ao#{i + 1}_of_ao4", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao4.uri},
          publish: true
        ))
      end

      31.times do |i| # 2 batches
        instance_variable_set("@ao#{i + 1}_of_ao5", create(:archival_object,
          resource: {'ref' => @resource.uri},
          parent: {'ref' => @ao5.uri},
          publish: true
        ))
      end

      @ao1_of_ao6 = create(:archival_object,
        resource: {'ref' => @resource.uri},
        parent: {'ref' => @ao6.uri},
        publish: true
      )

      run_indexers
    end

    it 'should handle titles with mixed content appropriately' do
      visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

      resource = find(".infinite-tree-sidebar #resource_#{@resource.id}")
      expect(resource).to have_css('.node-body[title="This is a mixed content title"]')
      resource_mixed_content_span = resource.find('.root.node > .node-row span.emph.render-italic')
      expect(resource_mixed_content_span).to have_content('a mixed content')

      ao1 = find(".infinite-tree-sidebar #archival_object_#{@ao1.id}")
      expect(ao1).to have_css("#archival_object_#{@ao1.id} > .node-row > .node-body[title='This is another mixed content title']")
      ao1_mixed_content_span = ao1.find("#archival_object_#{@ao1.id} > .node-row span.emph.render-italic")
      expect(ao1_mixed_content_span).to have_content('another mixed content')

      ao2 = find(".infinite-tree-sidebar #archival_object_#{@ao2.id}")
      ao2_title = ao2.find("#archival_object_#{@ao2.id} > .node-row .node-title")
      expect(ao2_title).to_not have_css('span.emph.render-italic')
      expect(ao2_title).to have_content('This is not a mixed content title')
    end

    context 'when AppConfig[:pui_collection_org_sidebar_position] is set to left' do
      before :each do
        allow(AppConfig).to receive(:[]).with(:pui_collection_org_sidebar_position) { 'left' }
      end

      it 'is positioned on the left side of the resource show and infinite views' do
        visit "/repositories/#{@repo.id}/resources/#{@resource.id}"

        wait_for_jquery
        expect(sidebar_left_coordinate).to be < content_left_coordinate
        expect(sidebar_right_coordinate).to eq content_left_coordinate

        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

        wait_for_jquery
        expect(sidebar_left_coordinate).to be < content_left_coordinate
        expect(sidebar_right_coordinate).to eq content_left_coordinate
      end

      it 'is positioned on the left side of the objects show view' do
        visit "/repositories/#{@repo.id}/digital_objects/#{@do.id}"

        wait_for_jquery
        expect(sidebar_left_coordinate).to be < content_left_coordinate
        expect(sidebar_right_coordinate).to eq content_left_coordinate

        visit "/repositories/#{@repo.id}/digital_object_components/#{@doc.id}"

        wait_for_jquery
        expect(sidebar_left_coordinate).to be < content_left_coordinate
        expect(sidebar_right_coordinate).to eq content_left_coordinate
      end

      it 'resizes appropriately via mouse drag' do
        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

        sidebar = find('.infinite-tree-sidebar')
        sidebar_handle = find('.resizable-sidebar-handle')
        content = find('.infinite-records-container')

        sidebar_left_initial = sidebar_left_coordinate
        sidebar_right_initial = sidebar_right_coordinate

        sidebar_handle.drag_to(content)

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq sidebar_left_initial
        expect(sidebar_right_coordinate).to be > sidebar_right_initial

        sidebar_right_increase = sidebar_right_coordinate

        sidebar_handle.drag_to(sidebar)

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq sidebar_left_initial
        expect(sidebar_right_coordinate).to be < sidebar_right_increase
      end

      it 'resizes appropriately via keyboard arrow keys' do
        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

        sidebar_handle = find('.resizable-sidebar-handle')

        sidebar_left_initial = sidebar_left_coordinate
        sidebar_right_initial = sidebar_right_coordinate

        sidebar_handle.send_keys(:tab)
        sidebar_handle.send_keys(:up)

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq sidebar_left_initial
        expect(sidebar_right_coordinate).to be > sidebar_right_initial

        sidebar_right_increase1 = sidebar_right_coordinate

        sidebar_handle.send_keys(:down)

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq sidebar_left_initial
        expect(sidebar_right_coordinate).to be < sidebar_right_increase1

        sidebar_right_decrease1 = sidebar_right_coordinate

        sidebar_handle.send_keys(:right)

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq sidebar_left_initial
        expect(sidebar_right_coordinate).to be > sidebar_right_decrease1

        sidebar_right_increase2 = sidebar_right_coordinate

        sidebar_handle.send_keys(:left)

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq sidebar_left_initial
        expect(sidebar_right_coordinate).to be < sidebar_right_increase2
      end
    end

    context 'when AppConfig[:pui_collection_org_sidebar_position] is set to right' do
      before :each do
        allow(AppConfig).to receive(:[]).with(:pui_collection_org_sidebar_position) { 'right' }
      end

      it 'is positioned on the right side of the show and infinite views' do
        visit "/repositories/#{@repo.id}/resources/#{@resource.id}"

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq content_right_coordinate
        expect(sidebar_right_coordinate).to be > content_right_coordinate

        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq content_right_coordinate
        expect(sidebar_right_coordinate).to be > content_right_coordinate
      end

      it 'is positioned on the right side of the objects show view' do
        visit "/repositories/#{@repo.id}/digital_objects/#{@do.id}"

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq content_right_coordinate
        expect(sidebar_right_coordinate).to be > content_right_coordinate

        visit "/repositories/#{@repo.id}/digital_object_components/#{@doc.id}"

        wait_for_jquery
        expect(sidebar_left_coordinate).to eq content_right_coordinate
        expect(sidebar_right_coordinate).to be > content_right_coordinate
      end

      it 'resizes appropriately via mouse drag' do
        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

        sidebar = find('.infinite-tree-sidebar')
        sidebar_handle = find('.resizable-sidebar-handle')
        content = find('.infinite-records-container')

        sidebar_right_initial = sidebar_right_coordinate
        sidebar_left_initial = sidebar_left_coordinate

        sidebar_handle.drag_to(content)

        wait_for_jquery
        expect(sidebar_right_coordinate).to eq sidebar_right_initial
        expect(sidebar_left_coordinate).to be < sidebar_left_initial

        sidebar_left_increase = sidebar_left_coordinate

        sidebar_handle.drag_to(sidebar)

        wait_for_jquery
        expect(sidebar_right_coordinate).to eq sidebar_right_initial
        expect(sidebar_left_coordinate).to be > sidebar_left_increase
      end

      it 'resizes appropriately via keyboard arrow keys' do
        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"

        sidebar = find('.infinite-tree-sidebar')
        sidebar_handle = find('.resizable-sidebar-handle')
        content = find('.infinite-records-container')

        sidebar_right_initial = sidebar_right_coordinate
        sidebar_left_initial = sidebar_left_coordinate

        sidebar_handle.send_keys(:tab)
        sidebar_handle.send_keys(:up)

        wait_for_jquery
        expect(sidebar_right_coordinate).to eq sidebar_right_initial
        expect(sidebar_left_coordinate).to be < sidebar_left_initial

        sidebar_left_increase1 = sidebar_left_coordinate

        sidebar_handle.send_keys(:down)

        wait_for_jquery
        expect(sidebar_right_coordinate).to eq sidebar_right_initial
        expect(sidebar_left_coordinate).to be > sidebar_left_increase1

        sidebar_left_decrease1 = sidebar_left_coordinate

        sidebar_handle.send_keys(:left)

        wait_for_jquery
        expect(sidebar_right_coordinate).to eq sidebar_right_initial
        expect(sidebar_left_coordinate).to be < sidebar_left_decrease1

        sidebar_left_increase2 = sidebar_left_coordinate

        sidebar_handle.send_keys(:right)

        wait_for_jquery
        expect(sidebar_right_coordinate).to eq sidebar_right_initial
        expect(sidebar_left_coordinate).to be > sidebar_left_increase2
      end
    end

    describe 'parent nodes' do
      before(:each) do
        visit "/repositories/#{@repo.id}/resources/#{@resource.id}/collection_organization"
        @container = page.find('#infinite-tree-container')
        @ao3_node = page.find("#archival_object_#{@ao3.id}")
      end

      it 'are collapsed by default' do
        num_first_level_nodes = page.all('#infinite-tree .root.node > .node-children > .node').count
        num_all_nodes = page.all('#infinite-tree .root.node .node').count
        expect(num_first_level_nodes).to eq num_all_nodes

        [@ao3, @ao4, @ao5, @ao6].each do |parent|
          node = page.find("#archival_object_#{parent.id}")
          expect(node['aria-expanded']).to eq "false"
          expect(node['data-has-expanded']).to eq "false"
          expect(node).to have_css('.node-expand-icon:not(.expanded)')
        end
      end

      it 'are expanded and collapsed by clicking the "expand" button' do
        @ao3_node.find('.node-expand').click
        expect(@ao3_node['aria-expanded']).to eq "true"
        expect(@ao3_node['data-has-expanded']).to eq "true"
        expect(@ao3_node).to have_css('.node-expand-icon.expanded')
        expect(@ao3_node).to have_css('& > .node-children > .node', count: 30, visible: true)

        @ao3_node.find('.node-expand').click
        expect(@ao3_node['aria-expanded']).to eq "false"
        expect(@ao3_node['data-has-expanded']).to eq "true"
        expect(@ao3_node).to have_css('.node-expand-icon:not(.expanded)')
        expect(@ao3_node).to have_css('& > .node-children > .node', count: 30, visible: false)
      end

      it 'children are loaded in "batches" on scroll when the parent has more children than the configured batch size' do
        @ao3_node.find('.node-expand').click
        expect(@ao3_node).to have_css('& > .node-children > li', count: 34, visible: :all)
        expect(@ao3_node).to have_css('& > .node-children > li.node', count: 30, visible: true)
        expect(@ao3_node).to have_css('& > .node-children > li:nth-last-child(-n+4)[data-batch-placeholder]', count: 4, visible: false)

        observer_node = @ao3_node.find('[data-observe-next-batch="true"]')
        @container.scroll_to(observer_node, align: :center)

        expect(@ao3_node).to have_css('& > .node-children > li', count: 63, visible: :all)
        expect(@ao3_node).to have_css('& > .node-children > li.node', count: 60, visible: true)
        expect(@ao3_node).to have_css('& > .node-children > li:nth-last-child(-n+3)[data-batch-placeholder]', count: 3, visible: false)
      end

      it 'hide all children when collapsed' do
        @ao3_node.find('.node-expand').click

        observer_node_1 = @ao3_node.find('[data-observe-offset="1"]')
        @container.scroll_to(observer_node_1, align: :center)
        observer_node_2 = @ao3_node.find('[data-observe-offset="2"]')
        @container.scroll_to(observer_node_2, align: :center)
        observer_node_3 = @ao3_node.find('[data-observe-offset="3"]')
        @container.scroll_to(observer_node_3, align: :center)
        observer_node_4 = @ao3_node.find('[data-observe-offset="4"]')
        @container.scroll_to(observer_node_4, align: :center)
        expect(@ao3_node).to have_css('& > .node-children > li', count: 121, visible: true)
        expect(@ao3_node).not_to have_css('& > .node-children > [data-batch-placeholder]')

        @ao3_node.find('.node-expand').click
        expect(@ao3_node).to have_css('& > .node-children > li', count: 121, visible: false)
      end
    end
  end

  describe 'Load All Records' do
    before(:all) do
      set_repo(@repo)
      @res_1wp = create(:resource,
        title: 'Collection with 1 waypoint of records',
        publish: true
      )
      2.times do |i|
        instance_variable_set("@ao#{i + 1}_1wp", create(:archival_object,
          resource: {'ref' => @res_1wp.uri},
          title: "AO #{i + 1}",
          publish: true
        ))
      end

      @res_2wp = create(:resource,
        title: 'Collection with 2 waypoints of records',
        publish: true
      )
      5.times do |i|
        instance_variable_set("@ao#{i + 1}_2wp", create(:archival_object,
          resource: {'ref' => @res_2wp.uri},
          title: "AO #{i + 1}",
          publish: true
        ))
      end

      @res_3wp = create(:resource,
        title: 'Collection with 3 waypoints of records',
        publish: true
      )
      10.times do |i|
        instance_variable_set("@ao#{i + 1}_3wp", create(:archival_object,
          resource: {'ref' => @res_3wp.uri},
          title: "AO #{i + 1}",
          publish: true
        ))
      end

      @res_4wp = create(:resource,
        title: 'Collection with 4 waypoints of records',
        publish: true
      )
      15.times do |i|
        instance_variable_set("@ao#{i + 1}_4wp", create(:archival_object,
          resource: {'ref' => @res_4wp.uri},
          title: "AO #{i + 1}",
          publish: true
        ))
      end

      @res_5wp = create(:resource,
        title: 'Collection with 5 waypoints of records',
        publish: true
      )
      20.times do |i|
        instance_variable_set("@ao#{i + 1}_5wp", create(:archival_object,
          resource: {'ref' => @res_5wp.uri},
          title: "AO #{i + 1}",
          publish: true
        ))
      end

      @res_10wp = create(:resource,
        title: 'Collection with 10 waypoints of records',
        publish: true
      )
      45.times do |i|
        instance_variable_set("@ao#{i + 1}_10wp", create(:archival_object,
          resource: {'ref' => @res_10wp.uri},
          title: "AO #{i + 1}",
          publish: true
        ))
      end

      run_indexers
    end

    it 'is not shown for a resource with less than 3 waypoints of records' do
      visit "/repositories/#{@repo.id}/resources/#{@res_1wp.id}/collection_organization"
      expect(page).not_to have_css('#load-all-section')

      visit "/repositories/#{@repo.id}/resources/#{@res_2wp.id}/collection_organization"
      expect(page).not_to have_css('#load-all-section')
    end

    it 'is shown after page load for a resource with more than 2 waypoints of records' do
      visit "/repositories/#{@repo.id}/resources/#{@res_3wp.id}/collection_organization"
      expect(page).to have_css('#load-all-section')
    end

    it 'is not shown for a resource with 3 waypoints after page load with a url fragment '\
    'that points to a record in the second waypoint' do
      visit "/repositories/#{@repo.id}/resources/#{@res_3wp.id}/collection_organization#tree::archival_object_#{@ao5_3wp.id}"
      expect(page).not_to have_css('#load-all-section')
    end

    it 'is shown for a resource with 3 waypoints after page load with a url fragment '\
    'that points to a record in the first or third waypoint' do
      visit "/repositories/#{@repo.id}/resources/#{@res_3wp.id}/collection_organization#tree::archival_object_#{@ao4_3wp.id}"
      expect(page).to have_css('#load-all-section')

      visit "/repositories/#{@repo.id}/resources/#{@res_3wp.id}/collection_organization#tree::archival_object_#{@ao10_3wp.id}"
      expect(page).to have_css('#load-all-section')
    end

    it 'is shown for a resource with more than 3 waypoints regardless of any url fragment' do
      visit "/repositories/#{@repo.id}/resources/#{@res_4wp.id}/collection_organization#tree::archival_object_#{@ao2_4wp.id}"
      expect(page).to have_css('#load-all-section')

      visit "/repositories/#{@repo.id}/resources/#{@res_4wp.id}/collection_organization#tree::archival_object_#{@ao7_4wp.id}"
      expect(page).to have_css('#load-all-section')

      visit "/repositories/#{@repo.id}/resources/#{@res_4wp.id}/collection_organization#tree::archival_object_#{@ao11_4wp.id}"
      waypoints = page.all('#infinite-records-container .waypoint')
      expect(page).to have_css('#load-all-section')

      visit "/repositories/#{@repo.id}/resources/#{@res_4wp.id}/collection_organization#tree::archival_object_#{@ao15_4wp.id}"
      expect(page).to have_css('#load-all-section')
    end

    it 'is set to download new records on scroll by default' do
      visit "/repositories/#{@repo.id}/resources/#{@res_3wp.id}/collection_organization"
      expect(page).to have_css('input#load-all-state:not(:checked)')
    end

    it 'shows the total number of records in the alert message' do
      visit "/repositories/#{@repo.id}/resources/#{@res_4wp.id}/collection_organization"
      total = page.find('#infinite-records-container')['data-total-records']
      load_all = page.find('#load-all-section')
      expect(load_all).to have_text("This collection contains a large number of records (#{total}).")
    end

    it 'shows the percentage of records that have been loaded after page load' do
      visit "/repositories/#{@repo.id}/resources/#{@res_4wp.id}/collection_organization"

      loaded_waypoints = page.all('#infinite-records-container .waypoint.populated')
      expect(loaded_waypoints.length).to eq 2

      loaded_records = page.all('#infinite-records-container .infinite-record-record')
      total_records = page.find('#infinite-records-container')['data-total-records']
      percent_loaded = (loaded_records.length.to_f / total_records.to_f * 100).round
      percent_label = page.find('#load-all-showing-percent')
      expect(percent_label).to have_text("#{percent_loaded}%")
    end

    it 'updates the percent showing label as more waypoints are loaded' do
      visit "/repositories/#{@repo.id}/resources/#{@res_4wp.id}/collection_organization"

      expect(page).to have_css('#infinite-records-container .waypoint.populated[data-waypoint-number="0"]')
      expect(page).to have_css('#infinite-records-container .waypoint.populated[data-waypoint-number="1"]')
      expect(page).to have_css('#infinite-records-container .waypoint:not(.populated)[data-waypoint-number="2"]')
      percent_start = page.find('#load-all-showing-percent').text[0..-2].to_i

      container = page.find('#infinite-records-container')
      second_record = page.find('#infinite-records-container [data-record-number="1"]')
      container.scroll_to(second_record)

      expect(page).to have_css('#infinite-records-container .waypoint.populated[data-waypoint-number="2"]')
      percent_new = page.find('#load-all-showing-percent').text[0..-2].to_i
      expect(percent_new).to be > percent_start
    end

    it 'works by clicking on the toggle switch' do
      visit "/repositories/#{@repo.id}/resources/#{@res_3wp.id}/collection_organization"

      expect(page).to have_css('#infinite-records-container', visible: true)
      page.find('.load-all__label-toggle').click
      expect(page).to have_css('#infinite-records-container', visible: false)

    end

    it 'works by keyboard' do
      visit "/repositories/#{@repo.id}/resources/#{@res_3wp.id}/collection_organization"
      input = page.find('input#load-all-state:not(:checked)')
      input.send_keys(:tab)
      input.send_keys(:space)
      expect(page).to have_css('input#load-all-state:checked')
    end

    it 'shows a spinner on state change and removes the spinner once all records are loaded' do
      visit "/repositories/#{@repo.id}/resources/#{@res_10wp.id}/collection_organization"
      expect(page).to have_css('#records-loading-dialog', visible: false)

      wait_for_jquery

      # There is no dialog 'open' event so listen for 'close' which implies it was open
      page.execute_script(<<~JS)
        window.dialogClosed = false;
        const dialog = document.querySelector('#records-loading-dialog');
        dialog.addEventListener('close', () => {
          window.dialogClosed = true;
        });
      JS

      expect(page.evaluate_script('window.dialogClosed')).to eq false
      page.find('.load-all__label-toggle').click

      wait_for_jquery

      expect(page.evaluate_script('window.dialogClosed')).to eq true
    end

    it 'removes itself after all records are loaded' do
      visit "/repositories/#{@repo.id}/resources/#{@res_3wp.id}/collection_organization"
      expect(page).to have_css('#load-all-section', visible: true)
      page.find('.load-all__label-toggle').click

      wait_for_jquery

      expect(page).to have_css('#load-all-section', visible: false)
    end

    context "when the number of waypoints does not exceed 'infinite_records_main_max_concurrent_waypoint_fetches'" do
      it 'loads all remaining records from the main thread' do
        visit "/repositories/#{@repo.id}/resources/#{@res_5wp.id}/collection_organization"

        wait_for_jquery

        total_records = page.find('#infinite-records-container')['data-total-records']
        num_empty_waypoints_start = page.all('#infinite-records-container .waypoint:not(.populated)').length
        expect(page).not_to have_css('#infinite-records-container .waypoint.populated .infinite-record-record', count: total_records.to_i)

        # Add a wrapper function around `window.fetch()` that increments a number when
        # the browser's main thread makes a fetch call.
        page.execute_script(<<~JS)
          window.loadAllFetchCount = 0;
          window.fetch = ((originalFetch) => {
            return (...args) => {
              window.loadAllFetchCount++;
              return originalFetch(...args);
            };
          })(window.fetch);
        JS

        expect(page.evaluate_script('window.loadAllFetchCount')).to eq 0
        page.find('.load-all__label-toggle').click

        wait_for_jquery

        expect(page).to have_css('#infinite-records-container .waypoint.populated .infinite-record-record', count: total_records.to_i)
        expect(page.evaluate_script('window.loadAllFetchCount')).to eq num_empty_waypoints_start
      end
    end

    context "when the number of waypoints exceeds 'infinite_records_main_max_concurrent_waypoint_fetches'" do
      it 'loads all remaining records from a background thread' do
        visit "/repositories/#{@repo.id}/resources/#{@res_10wp.id}/collection_organization"

        wait_for_jquery

        total_records = page.find('#infinite-records-container')['data-total-records']
        expect(page).not_to have_css('#infinite-records-container .waypoint.populated .infinite-record-record', count: total_records.to_i)

        # Add a wrapper function around `window.fetch()` that increments a number when
        # the browser's main thread makes a fetch call. Web workers don't have access
        # to `window`, so its fetch calls won't be counted.
        page.execute_script(<<~JS)
          window.loadAllFetchCount = 0;
          window.fetch = ((originalFetch) => {
            return (...args) => {
              window.loadAllFetchCount++;
              return originalFetch(...args);
            };
          })(window.fetch);
        JS

        expect(page.evaluate_script('window.loadAllFetchCount')).to eq 0
        page.find('.load-all__label-toggle').click

        wait_for_jquery

        expect(page).to have_css('#infinite-records-container .waypoint.populated .infinite-record-record', count: total_records.to_i)
        expect(page.evaluate_script('window.loadAllFetchCount')).to eq 0
      end
    end
  end
end
