# frozen_string_literal: true

module Bridgetown
  module Commands
    class Build < Command
      class << self
        # Create the Mercenary command for the Bridgetown CLI for this Command
        def init_with_program(prog)
          prog.command(:build) do |c|
            c.syntax      "build [options]"
            c.description "Build your site"
            c.alias :b

            add_build_options(c)

            c.action do |_, options|
              options["serving"] = false
              process_with_graceful_fail(c, options, self)
            end
          end
        end

        # Build your bridgetown site
        # Continuously watch if `watch` is set to true in the config.
        def process(options)
          # Adjust verbosity quickly
          Bridgetown.logger.adjust_verbosity(options)

          Bridgetown.logger.info "#", "Your Bridgetown #{Bridgetown::VERSION} build is about to begin…"

          options = configuration_from_options(options)
          site = Bridgetown::Site.new(options)

          if options.fetch("skip_initial_build", false)
            Bridgetown.logger.warn "Build Warning:", "Skipping the initial build." \
                               " This may result in an out-of-date site."
          else
            build(site, options)
          end

          if options.fetch("detach", false)
            Bridgetown.logger.info "Auto-regeneration:",
                                   "disabled when running server detached."
          elsif options.fetch("watch", false)
            watch(site, options)
          else
            Bridgetown.logger.info "Auto-regeneration:", "disabled. Use --watch to enable."
          end
        end

        # Build your Bridgetown site.
        #
        # site - the Bridgetown::Site instance to build
        # options - A Hash of options passed to the command
        #
        # Returns nothing.
        def build(site, options)
          t = Time.now
          source = File.expand_path(options["source"])
          destination = File.expand_path(options["destination"])
          incremental = options["incremental"]
          Bridgetown.logger.info "Source:", source
          Bridgetown.logger.info "Destination:", destination
          Bridgetown.logger.info "Incremental build:",
                                 (incremental ? "enabled" : "disabled. Enable with --incremental")
          Bridgetown.logger.info "Generating…"
          process_site(site)
          Bridgetown.logger.info "Done! 🎉", "Completed in #{(Time.now - t).round(3)} seconds."
        end

        # Private: Watch for file changes and rebuild the site.
        #
        # site - A Bridgetown::Site instance
        # options - A Hash of options passed to the command
        #
        # Returns nothing.
        def watch(site, options)
          # Warn Windows users that they might need to upgrade.
          if Utils::Platforms.bash_on_windows?
            Bridgetown.logger.warn "",
                                   "Auto-regeneration may not work on some Windows versions."
            Bridgetown.logger.warn "",
                                   "Please see: https://github.com/Microsoft/BashOnWindows/issues/216"
            Bridgetown.logger.warn "",
                                   "If it does not work, please upgrade Bash on Windows or "\
                                   "run Bridgetown with --no-watch."
          end

          #          External.require_with_graceful_fail "bridgetown-watch"
          Bridgetown::Watcher.watch(options, site)
        end
      end
    end
  end
end
