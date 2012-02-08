require 'capistrano/recipes/deploy/strategy/remote'

module Capistrano
  module Deploy
    module Strategy
      class RsyncWithRemoteCache < Remote

        # The deployment method itself, in three major steps.
        def deploy!

          # Step 1: Update the local cache.
          system(command)
          File.open(File.join(local_cache, "REVISION"), "w") { |f| f.puts(revision) }

          # Step 2: Update the remote cache.
          logger.trace "copying local cache to remote"
          if ENV["OS"]=='Windows_NT'
            if ENV["USE_PLINK"]=="1"
              rsync_cmd = 'config\deploy\callrsync.bat --rsh="plink" --chmod=ug+w,Fugo+r,Dugo+X'
            else
              rsync_cmd = 'rsync --rsh="ssh -i ' + ENV['SSH_KEYFILE'] + '" --chmod=ug+w,Fugo+r,Dugo+X'
            end
          else
            rsync_cmd = 'rsync'
          end
          find_servers(:roles => :app, :except => { :no_release => true }).each do |server|
            cmdline = "#{rsync_cmd} #{rsync_options} #{local_cache}/ #{rsync_host(server)}:#{repository_cache}/"
            logger.trace cmdline
            system(cmdline)
          end

          # Step 3: Copy the remote cache into place.
          run("#{rsync_cmd} -a --delete #{repository_cache}/ #{configuration[:release_path]}/ && #{mark}")
        end

        # Defines commands that should be checked for by deploy:check. These include the SCM command
        # on the local end, and rsync on both ends. Note that the SCM command is not needed on the
        # remote end.
        def check!
          super.check do |d|
            d.local.command(source.command)
            d.local.command('rsync')
            d.remote.command('rsync')
          end
        end

        private

        # Path to the remote cache. We use a variable name and default that are compatible with
        # the stock remote_cache strategy, for easy migration.
        def repository_cache
          File.join(shared_path, configuration[:repository_cache] || "cached-copy")
        end

        # Path to the local cache. If not specified in the Capfile, we use an arbitrary default.
        def local_cache
          configuration[:local_cache] || ".rsync_cache"
        end

        # Options to use for rsync in step 2. If not specified in the Capfile, we use the default
        # from prior versions.
        def rsync_options
          configuration[:rsync_options] || "-az --delete"
        end

        # Returns the host used in the rsync command, prefixed with user@ if user is specified in Capfile.
        def rsync_host(server)
          if configuration[:user]
            "#{configuration[:user]}@#{server.host}"
          else
            server.host
          end
        end
        
        # Command to get source from SCM on the local side. If the local_cache directory exists,
        # we check to see if it's an SCM checkout that matches the currently configured repository.
        # If it matches, we update it. If it doesn't match (either it's for another repository or
        # not a checkout at all), we remove the directory and recreate it with a fresh SCM checkout.
        # If the directory doesn't exist, we create it with a fresh SCM checkout.
        #
        # FIXME: The above logic only takes place if the SCM is Subversion. At some point, similar logic
        # will probably be necessary for Git and other SCMs we might use.
        #
        # TODO: punt in some sensible way if local_cache exists but is a regular file.
        def command
          if (configuration[:scm] == :subversion &&
              `svn info #{local_cache} | sed -n 's/URL: //p'`.strip != configuration[:repository])
            logger.trace "repository has changed; removing old local cache"
            system("rm -rf #{local_cache}")
          end
          if File.exists?(local_cache) && File.directory?(local_cache)
            logger.trace "updating local cache to revision #{revision}"
            cmd = source.sync(revision, local_cache)
          else
            logger.trace "creating local cache with revision #{revision}"
            File.delete(local_cache) if File.exists?(local_cache)
            Dir.mkdir(File.dirname(local_cache)) unless File.directory?(File.dirname(local_cache))
            cmd = source.checkout(revision, local_cache)
          end
          cmd
        end
      end
    end
  end
end
