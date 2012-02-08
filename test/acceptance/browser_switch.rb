ENV['WATIR_BROWSER'] ||= 'firefox'
ENV['WATIR_BROWSER'] = ENV['WATIR_BROWSER'].downcase



class WatirBrowser
  class << self
    def name
      @name ||= ENV['WATIR_BROWSER']
    end
    
    def ie?
      return ::WatirBrowser.name == 'ie'
    end
    
    def firefox?
      return ::WatirBrowser.name == 'firefox'
    end

    case ::WatirBrowser.name
    when 'ie'
      require 'watir'
      require 'watir/contrib/visible'
      #for auto clicking of javascript windows
      require 'watir/contrib/enabled_popup'
      require 'watir/winClicker' 
      require 'watir/screen_capture.rb'
  
      # Reimplement goto to re-open the browser if it is closed unexpectedly.
      class Watir::IE
    
        def goto(url)
          if not self.exists?
            RAILS_DEFAULT_LOGGER.debug('IE instance terminated. Opening new window.')
            @closing = false
            self.send(:initialize)
            self.speed = :fast
          end
          @ie.navigate(url)
          wait
          return @down_load_time
        end
      end
  
      def get_browser
        browser = Watir::IE.start 
        browser.set_fast_speed
        browser
      end

      def row_with_head(row)
        row
      end
      
      def first_item
        1
      end
      
      def item_index(ix)
        ix
      end

    when 'firefox'  
      require 'firewatir' 
      require 'watir/waiter'
      #require 'appscript' if ENV['OS_ENV'] == 'Mac'
      # require File.dirname(__FILE__) + '/firefox_app'
      # puts "launch firefox"
      # FirefoxApp.instance.launch(false)
      def get_browser
        case RUBY_PLATFORM
          when /darwin/i
            require 'appscript'
            if !defined? @@browser
              if Appscript.app('System Events').processes['Firefox'].exists()
                puts "stopping Firefox..."
                sleep 1
                Appscript.app('Firefox').quit
                sleep 3
                puts "hopefully Firefox is stopped by now. so we can start it. Gah"
              end
            end
        end
        tries = 1
        begin
          @@browser ||= FireWatir::Firefox.new(:waitTime => tries+3)
        rescue Exception => e
          puts "e: #{e.inspect}"
          case RUBY_PLATFORM
            when /darwin/i
              sleep tries
              puts "trying to start Firefox #{tries}"
              if Appscript.app('System Events').processes['Firefox'].exists()
                puts "stopping existing Firefox..."
                Appscript.app('Firefox').quit
              end
              retry if tries < 5
          end
        end
        
        at_exit do
          if @@browser
            puts "closing firefox"
            begin Timeout.timeout(2) do
              if defined? Appscript 
                begin
                  if Appscript.app('System Events').processes['Firefox'].exists
                    Appscript.app('Firefox').quit
                  end
                rescue RuntimeError, Exception
                  @@browser.close
                end
              else
                @@browser.close
              end
            end rescue Timeout::Error end
            @@browser = nil
          end
        end
        @@browser
      end
      
      def first_item
        0
      end
      
      def item_index(ix)
        ix-1
      end

      def row_with_head(row)
        row-1
      end
      
      
    when 'safari'
      require 'safariwatir'
      module Watir
        class Safari
          def maximize; end
          def wait;end
          def close; end
        end
      end
    
      def get_browser
        Watir::Safari.start
      end
    else
      require 'watir'  
    end
  end
end

