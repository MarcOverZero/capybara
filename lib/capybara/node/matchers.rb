# frozen_string_literal: true
module Capybara
  module Node
    module Matchers

      ##
      #
      # Checks if a given selector is on the page or a descendant of the current node.
      #
      #     page.has_selector?('p#foo')
      #     page.has_selector?(:xpath, './/p[@id="foo"]')
      #     page.has_selector?(:foo)
      #
      # By default it will check if the expression occurs at least once,
      # but a different number can be specified.
      #
      #     page.has_selector?('p.foo', count: 4)
      #
      # This will check if the expression occurs exactly 4 times.
      #
      # It also accepts all options that {Capybara::Node::Finders#all} accepts,
      # such as :text and :visible.
      #
      #     page.has_selector?('li', text: 'Horse', visible: true)
      #
      # has_selector? can also accept XPath expressions generated by the
      # XPath gem:
      #
      #     page.has_selector?(:xpath, XPath.descendant(:p))
      #
      # @param (see Capybara::Node::Finders#all)
      # @param args
      # @option args [Integer] :count (nil)     Number of times the text should occur
      # @option args [Integer] :minimum (nil)   Minimum number of times the text should occur
      # @option args [Integer] :maximum (nil)   Maximum number of times the text should occur
      # @option args [Range]   :between (nil)   Range of times that should contain number of times text occurs
      # @return [Boolean]                       If the expression exists
      #
      def has_selector?(*args, &optional_filter_block)
        assert_selector(*args, &optional_filter_block)
      rescue Capybara::ExpectationNotMet
        return false
      end

      ##
      #
      # Checks if a given selector is not on the page or a descendant of the current node.
      # Usage is identical to Capybara::Node::Matchers#has_selector?
      #
      # @param (see Capybara::Node::Finders#has_selector?)
      # @return [Boolean]
      #
      def has_no_selector?(*args, &optional_filter_block)
        assert_no_selector(*args, &optional_filter_block)
      rescue Capybara::ExpectationNotMet
        return false
      end

      ##
      #
      # Asserts that a given selector is on the page or a descendant of the current node.
      #
      #     page.assert_selector('p#foo')
      #     page.assert_selector(:xpath, './/p[@id="foo"]')
      #     page.assert_selector(:foo)
      #
      # By default it will check if the expression occurs at least once,
      # but a different number can be specified.
      #
      #     page.assert_selector('p#foo', count: 4)
      #
      # This will check if the expression occurs exactly 4 times. See
      # {Capybara::Node::Finders#all} for other available result size options.
      #
      # If a :count of 0 is specified, it will behave like {#assert_no_selector};
      # however, use of that method is preferred over this one.
      #
      # It also accepts all options that {Capybara::Node::Finders#all} accepts,
      # such as :text and :visible.
      #
      #     page.assert_selector('li', text: 'Horse', visible: true)
      #
      # `assert_selector` can also accept XPath expressions generated by the
      # XPath gem:
      #
      #     page.assert_selector(:xpath, XPath.descendant(:p))
      #
      # @param (see Capybara::Node::Finders#all)
      # @option options [Integer] :count (nil)    Number of times the expression should occur
      # @raise [Capybara::ExpectationNotMet]      If the selector does not exist
      #
      def assert_selector(*args, &optional_filter_block)
        _verify_selector_result(args, optional_filter_block) do |result, query|
          unless result.matches_count? && ((!result.empty?) || query.expects_none?)
            raise Capybara::ExpectationNotMet, result.failure_message
          end
        end
      end

      # Asserts that all of the provided selectors are present on the given page
      # or descendants of the current node.  If options are provided, the assertion
      # will check that each locator is present with those options as well (other than :wait).
      #
      #   page.assert_all_of_selectors(:custom, 'Tom', 'Joe', visible: all)
      #   page.assert_all_of_selectors(:css, '#my_div', 'a.not_clicked')
      #
      # It accepts all options that {Capybara::Node::Finders#all} accepts,
      # such as :text and :visible.
      #
      # The :wait option applies to all of the selectors as a group, so all of the locators must be present
      # within :wait (Defaults to Capybara.default_max_wait_time) seconds.
      #
      # @overload assert_all_of_selectors([kind = Capybara.default_selector], *locators, options = {})
      #
      def assert_all_of_selectors(*args, wait: session_options.default_max_wait_time, **options, &optional_filter_block)
        selector = if args.first.is_a?(Symbol) then args.shift else session_options.default_selector end
        synchronize(wait) do
          args.each do |locator|
            assert_selector(selector, locator, options, &optional_filter_block)
          end
        end
      end

      # Asserts that none of the provided selectors are present on the given page
      # or descendants of the current node. If options are provided, the assertion
      # will check that each locator is present with those options as well (other than :wait).
      #
      #   page.assert_none_of_selectors(:custom, 'Tom', 'Joe', visible: all)
      #   page.assert_none_of_selectors(:css, '#my_div', 'a.not_clicked')
      #
      # It accepts all options that {Capybara::Node::Finders#all} accepts,
      # such as :text and :visible.
      #
      # The :wait option applies to all of the selectors as a group, so none of the locators must be present
      # within :wait (Defaults to Capybara.default_max_wait_time) seconds.
      #
      # @overload assert_none_of_selectors([kind = Capybara.default_selector], *locators, options = {})
      #
      def assert_none_of_selectors(*args, wait: session_options.default_max_wait_time, **options, &optional_filter_block)
        selector = if args.first.is_a?(Symbol) then args.shift else session_options.default_selector end
        synchronize(wait) do
          args.each do |locator|
            assert_no_selector(selector, locator, options, &optional_filter_block)
          end
        end
      end

      ##
      #
      # Asserts that a given selector is not on the page or a descendant of the current node.
      # Usage is identical to Capybara::Node::Matchers#assert_selector
      #
      # Query options such as :count, :minimum, :maximum, and :between are
      # considered to be an integral part of the selector. This will return
      # true, for example, if a page contains 4 anchors but the query expects 5:
      #
      #     page.assert_no_selector('a', minimum: 1) # Found, raises Capybara::ExpectationNotMet
      #     page.assert_no_selector('a', count: 4)   # Found, raises Capybara::ExpectationNotMet
      #     page.assert_no_selector('a', count: 5)   # Not Found, returns true
      #
      # @param (see Capybara::Node::Finders#assert_selector)
      # @raise [Capybara::ExpectationNotMet]      If the selector exists
      #
      def assert_no_selector(*args, &optional_filter_block)
        _verify_selector_result(args, optional_filter_block) do |result, query|
          if result.matches_count? && ((!result.empty?) || query.expects_none?)
            raise Capybara::ExpectationNotMet, result.negative_failure_message
          end
        end
      end
      alias_method :refute_selector, :assert_no_selector

      ##
      #
      # Checks if a given XPath expression is on the page or a descendant of the current node.
      #
      #     page.has_xpath?('.//p[@id="foo"]')
      #
      # By default it will check if the expression occurs at least once,
      # but a different number can be specified.
      #
      #     page.has_xpath?('.//p[@id="foo"]', count: 4)
      #
      # This will check if the expression occurs exactly 4 times.
      #
      # It also accepts all options that {Capybara::Node::Finders#all} accepts,
      # such as :text and :visible.
      #
      #     page.has_xpath?('.//li', text: 'Horse', visible: true)
      #
      # has_xpath? can also accept XPath expressions generate by the
      # XPath gem:
      #
      #     xpath = XPath.generate { |x| x.descendant(:p) }
      #     page.has_xpath?(xpath)
      #
      # @param [String] path                      An XPath expression
      # @param options                            (see Capybara::Node::Finders#all)
      # @option options [Integer] :count (nil)    Number of times the expression should occur
      # @return [Boolean]                         If the expression exists
      #
      def has_xpath?(path, **options, &optional_filter_block)
        has_selector?(:xpath, path, options, &optional_filter_block)
      end

      ##
      #
      # Checks if a given XPath expression is not on the page or a descendant of the current node.
      # Usage is identical to Capybara::Node::Matchers#has_xpath?
      #
      # @param (see Capybara::Node::Finders#has_xpath?)
      # @return [Boolean]
      #
      def has_no_xpath?(path, **options, &optional_filter_block)
        has_no_selector?(:xpath, path, options, &optional_filter_block)
      end

      ##
      #
      # Checks if a given CSS selector is on the page or a descendant of the current node.
      #
      #     page.has_css?('p#foo')
      #
      # By default it will check if the selector occurs at least once,
      # but a different number can be specified.
      #
      #     page.has_css?('p#foo', count: 4)
      #
      # This will check if the selector occurs exactly 4 times.
      #
      # It also accepts all options that {Capybara::Node::Finders#all} accepts,
      # such as :text and :visible.
      #
      #     page.has_css?('li', text: 'Horse', visible: true)
      #
      # @param [String] path                      A CSS selector
      # @param options                            (see Capybara::Node::Finders#all)
      # @option options [Integer] :count (nil)    Number of times the selector should occur
      # @return [Boolean]                         If the selector exists
      #
      def has_css?(path, **options, &optional_filter_block)
        has_selector?(:css, path, options, &optional_filter_block)
      end

      ##
      #
      # Checks if a given CSS selector is not on the page or a descendant of the current node.
      # Usage is identical to Capybara::Node::Matchers#has_css?
      #
      # @param (see Capybara::Node::Finders#has_css?)
      # @return [Boolean]
      #
      def has_no_css?(path, **options, &optional_filter_block)
        has_no_selector?(:css, path, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has a link with the given
      # text or id.
      #
      # @param [String] locator           The text or id of a link to check for
      # @param options
      # @option options [String, Regexp] :href    The value the href attribute must be
      # @return [Boolean]                 Whether it exists
      #
      def has_link?(locator=nil, **options, &optional_filter_block)
        has_selector?(:link, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has no link with the given
      # text or id.
      #
      # @param (see Capybara::Node::Finders#has_link?)
      # @return [Boolean]            Whether it doesn't exist
      #
      def has_no_link?(locator=nil, **options, &optional_filter_block)
        has_no_selector?(:link, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has a button with the given
      # text, value or id.
      #
      # @param [String] locator      The text, value or id of a button to check for
      # @return [Boolean]            Whether it exists
      #
      def has_button?(locator=nil, **options, &optional_filter_block)
        has_selector?(:button, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has no button with the given
      # text, value or id.
      #
      # @param [String] locator      The text, value or id of a button to check for
      # @return [Boolean]            Whether it doesn't exist
      #
      def has_no_button?(locator=nil, **options, &optional_filter_block)
        has_no_selector?(:button, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has a form field with the given
      # label, name or id.
      #
      # For text fields and other textual fields, such as textareas and
      # HTML5 email/url/etc. fields, it's possible to specify a :with
      # option to specify the text the field should contain:
      #
      #     page.has_field?('Name', with: 'Jonas')
      #
      # It is also possible to filter by the field type attribute:
      #
      #     page.has_field?('Email', type: 'email')
      #
      # Note: 'textarea' and 'select' are valid type values, matching the associated tag names.
      #
      # @param [String] locator                  The label, name or id of a field to check for
      # @option options [String, Regexp] :with   The text content of the field or a Regexp to match
      # @option options [String] :type           The type attribute of the field
      # @return [Boolean]                        Whether it exists
      #
      def has_field?(locator=nil, **options, &optional_filter_block)
        has_selector?(:field, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has no form field with the given
      # label, name or id. See {Capybara::Node::Matchers#has_field?}.
      #
      # @param [String] locator                  The label, name or id of a field to check for
      # @option options [String, Regexp] :with   The text content of the field or a Regexp to match
      # @option options [String] :type           The type attribute of the field
      # @return [Boolean]                        Whether it doesn't exist
      #
      def has_no_field?(locator=nil, **options, &optional_filter_block)
        has_no_selector?(:field, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has a radio button or
      # checkbox with the given label, value or id, that is currently
      # checked.
      #
      # @param [String] locator           The label, name or id of a checked field
      # @return [Boolean]                 Whether it exists
      #
      def has_checked_field?(locator=nil, **options, &optional_filter_block)
        has_selector?(:field, locator, options.merge(checked: true), &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has no radio button or
      # checkbox with the given label, value or id, that is currently
      # checked.
      #
      # @param [String] locator           The label, name or id of a checked field
      # @return [Boolean]                 Whether it doesn't exist
      #
      def has_no_checked_field?(locator=nil, **options, &optional_filter_block)
        has_no_selector?(:field, locator, options.merge(checked: true), &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has a radio button or
      # checkbox with the given label, value or id, that is currently
      # unchecked.
      #
      # @param [String] locator           The label, name or id of an unchecked field
      # @return [Boolean]                 Whether it exists
      #
      def has_unchecked_field?(locator=nil, **options, &optional_filter_block)
        has_selector?(:field, locator, options.merge(unchecked: true), &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has no radio button or
      # checkbox with the given label, value or id, that is currently
      # unchecked.
      #
      # @param [String] locator           The label, name or id of an unchecked field
      # @return [Boolean]                 Whether it doesn't exist
      #
      def has_no_unchecked_field?(locator=nil, **options, &optional_filter_block)
        has_no_selector?(:field, locator, options.merge(unchecked: true), &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has a select field with the
      # given label, name or id.
      #
      # It can be specified which option should currently be selected:
      #
      #     page.has_select?('Language', selected: 'German')
      #
      # For multiple select boxes, several options may be specified:
      #
      #     page.has_select?('Language', selected: ['English', 'German'])
      #
      # It's also possible to check if the exact set of options exists for
      # this select box:
      #
      #     page.has_select?('Language', options: ['English', 'German', 'Spanish'])
      #
      # You can also check for a partial set of options:
      #
      #     page.has_select?('Language', with_options: ['English', 'German'])
      #
      # @param [String] locator                      The label, name or id of a select box
      # @option options [Array] :options             Options which should be contained in this select box
      # @option options [Array] :with_options        Partial set of options which should be contained in this select box
      # @option options [String, Array] :selected    Options which should be selected
      # @return [Boolean]                            Whether it exists
      #
      def has_select?(locator=nil, **options, &optional_filter_block)
        has_selector?(:select, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has no select field with the
      # given label, name or id. See {Capybara::Node::Matchers#has_select?}.
      #
      # @param (see Capybara::Node::Matchers#has_select?)
      # @return [Boolean]     Whether it doesn't exist
      #
      def has_no_select?(locator=nil, **options, &optional_filter_block)
        has_no_selector?(:select, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has a table with the given id
      # or caption:
      #
      #    page.has_table?('People')
      #
      # @param [String] locator                        The id or caption of a table
      # @return [Boolean]                              Whether it exist
      #
      def has_table?(locator=nil, **options, &optional_filter_block)
        has_selector?(:table, locator, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the page or current node has no table with the given id
      # or caption. See {Capybara::Node::Matchers#has_table?}.
      #
      # @param (see Capybara::Node::Matchers#has_table?)
      # @return [Boolean]       Whether it doesn't exist
      #
      def has_no_table?(locator=nil, **options, &optional_filter_block)
        has_no_selector?(:table, locator, options, &optional_filter_block)
      end

      ##
      #
      # Asserts that the current_node matches a given selector
      #
      #     node.assert_matches_selector('p#foo')
      #     node.assert_matches_selector(:xpath, '//p[@id="foo"]')
      #     node.assert_matches_selector(:foo)
      #
      # It also accepts all options that {Capybara::Node::Finders#all} accepts,
      # such as :text and :visible.
      #
      #     node.assert_matches_selector('li', text: 'Horse', visible: true)
      #
      # @param (see Capybara::Node::Finders#all)
      # @raise [Capybara::ExpectationNotMet]      If the selector does not match
      #
      def assert_matches_selector(*args, &optional_filter_block)
        _verify_match_result(args, optional_filter_block) do |result|
          raise Capybara::ExpectationNotMet, "Item does not match the provided selector" unless result.include? self
        end
      end

      def assert_not_matches_selector(*args, &optional_filter_block)
        _verify_match_result(args, optional_filter_block) do |result|
          raise Capybara::ExpectationNotMet, 'Item matched the provided selector' if result.include? self
        end
      end
      alias_method :refute_matches_selector, :assert_not_matches_selector

      ##
      #
      # Checks if the current node matches given selector
      #
      # @param (see Capybara::Node::Finders#has_selector?)
      # @return [Boolean]
      #
      def matches_selector?(*args, &optional_filter_block)
        assert_matches_selector(*args, &optional_filter_block)
      rescue Capybara::ExpectationNotMet
        return false
      end

      ##
      #
      # Checks if the current node matches given XPath expression
      #
      # @param [String, XPath::Expression] xpath The XPath expression to match against the current code
      # @return [Boolean]
      #
      def matches_xpath?(xpath, **options, &optional_filter_block)
        matches_selector?(:xpath, xpath, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the current node matches given CSS selector
      #
      # @param [String] css The CSS selector to match against the current code
      # @return [Boolean]
      #
      def matches_css?(css, **options, &optional_filter_block)
        matches_selector?(:css, css, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the current node does not match given selector
      # Usage is identical to Capybara::Node::Matchers#has_selector?
      #
      # @param (see Capybara::Node::Finders#has_selector?)
      # @return [Boolean]
      #
      def not_matches_selector?(*args, &optional_filter_block)
        assert_not_matches_selector(*args, &optional_filter_block)
      rescue Capybara::ExpectationNotMet
        return false
      end

      ##
      #
      # Checks if the current node does not match given XPath expression
      #
      # @param [String, XPath::Expression] xpath The XPath expression to match against the current code
      # @return [Boolean]
      #
      def not_matches_xpath?(xpath, **options, &optional_filter_block)
        not_matches_selector?(:xpath, xpath, options, &optional_filter_block)
      end

      ##
      #
      # Checks if the current node does not match given CSS selector
      #
      # @param [String] css The CSS selector to match against the current code
      # @return [Boolean]
      #
      def not_matches_css?(css, **options, &optional_filter_block)
        not_matches_selector?(:css, css, options, &optional_filter_block)
      end


      ##
      # Asserts that the page or current node has the given text content,
      # ignoring any HTML tags.
      #
      # @!macro text_query_params
      #   @overload $0(type, text, options = {})
      #     @param [:all, :visible] type               Whether to check for only visible or all text. If this parameter is missing or nil then we use the value of `Capybara.ignore_hidden_elements`, which defaults to `true`, corresponding to `:visible`.
      #     @param [String, Regexp] text               The string/regexp to check for. If it's a string, text is expected to include it. If it's a regexp, text is expected to match it.
      #     @option options [Integer] :count (nil)     Number of times the text is expected to occur
      #     @option options [Integer] :minimum (nil)   Minimum number of times the text is expected to occur
      #     @option options [Integer] :maximum (nil)   Maximum number of times the text is expected to occur
      #     @option options [Range]   :between (nil)   Range of times that is expected to contain number of times text occurs
      #     @option options [Numeric] :wait (Capybara.default_max_wait_time)      Maximum time that Capybara will wait for text to eq/match given string/regexp argument
      #     @option options [Boolean] :exact (Capybara.exact_text) Whether text must be an exact match or just substring
      #   @overload $0(text, options = {})
      #     @param [String, Regexp] text               The string/regexp to check for. If it's a string, text is expected to include it. If it's a regexp, text is expected to match it.
      #     @option options [Integer] :count (nil)     Number of times the text is expected to occur
      #     @option options [Integer] :minimum (nil)   Minimum number of times the text is expected to occur
      #     @option options [Integer] :maximum (nil)   Maximum number of times the text is expected to occur
      #     @option options [Range]   :between (nil)   Range of times that is expected to contain number of times text occurs
      #     @option options [Numeric] :wait (Capybara.default_max_wait_time)      Maximum time that Capybara will wait for text to eq/match given string/regexp argument
      #     @option options [Boolean] :exact (Capybara.exact_text) Whether text must be an exact match or just substring
      # @raise [Capybara::ExpectationNotMet] if the assertion hasn't succeeded during wait time
      # @return [true]
      #
      def assert_text(*args)
        _verify_text(args) do |count, query|
          unless query.matches_count?(count) && ((count > 0) || query.expects_none?)
            raise Capybara::ExpectationNotMet, query.failure_message
          end
        end
      end

      ##
      # Asserts that the page or current node doesn't have the given text content,
      # ignoring any HTML tags.
      #
      # @macro text_query_params
      # @raise [Capybara::ExpectationNotMet] if the assertion hasn't succeeded during wait time
      # @return [true]
      #
      def assert_no_text(*args)
        _verify_text(args) do |count, query|
          if query.matches_count?(count) && ((count > 0) || query.expects_none?)
            raise Capybara::ExpectationNotMet, query.negative_failure_message
          end
        end
      end

      ##
      # Checks if the page or current node has the given text content,
      # ignoring any HTML tags.
      #
      # Whitespaces are normalized in both node's text and passed text parameter.
      # Note that whitespace isn't normalized in passed regexp as normalizing whitespace
      # in regexp isn't easy and doesn't seem to be worth it.
      #
      # By default it will check if the text occurs at least once,
      # but a different number can be specified.
      #
      #     page.has_text?('lorem ipsum', between: 2..4)
      #
      # This will check if the text occurs from 2 to 4 times.
      #
      # @macro text_query_params
      # @return [Boolean]                            Whether it exists
      #
      def has_text?(*args)
        assert_text(*args)
      rescue Capybara::ExpectationNotMet
        return false
      end
      alias_method :has_content?, :has_text?

      ##
      # Checks if the page or current node does not have the given text
      # content, ignoring any HTML tags and normalizing whitespace.
      #
      # @macro text_query_params
      # @return [Boolean]  Whether it doesn't exist
      #
      def has_no_text?(*args)
        assert_no_text(*args)
      rescue Capybara::ExpectationNotMet
        return false
      end
      alias_method :has_no_content?, :has_no_text?

      def ==(other)
        self.eql?(other) || (other.respond_to?(:base) && base == other.base)
      end

    private

      def _verify_selector_result(query_args, optional_filter_block, &result_block)
        _set_query_session_options(query_args)
        query = Capybara::Queries::SelectorQuery.new(*query_args, &optional_filter_block)
        synchronize(query.wait) do
          result = query.resolve_for(self)
          result_block.call(result, query)
        end
        return true
      end

      def _verify_match_result(query_args, optional_filter_block, &result_block)
        _set_query_session_options(query_args)
        query = Capybara::Queries::MatchQuery.new(*query_args, &optional_filter_block)
        synchronize(query.wait) do
          result = query.resolve_for(self.query_scope)
          result_block.call(result)
        end
        return true
      end

      def _verify_text(query_args)
        _set_query_session_options(query_args)
        query = Capybara::Queries::TextQuery.new(*query_args)
        synchronize(query.wait) do
          count = query.resolve_for(self)
          yield(count, query)
        end
        return true
      end

      def _set_query_session_options(query_args)
        if query_args.last.is_a? Hash
          query_args.last[:session_options] = session_options
        else
          query_args.push(session_options: session_options)
        end
        query_args
      end
    end
  end
end
