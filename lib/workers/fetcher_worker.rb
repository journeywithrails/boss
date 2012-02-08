class FetcherWorker < BackgrounDRb::MetaWorker
  set_worker_name :fetcher_worker
  def create(args = nil)
    @config = YAML.load_file("#{RAILS_ROOT}/config/mail.yml")
    @config = @config[RAILS_ENV].to_options
    @fetcher = Fetcher.create({:receiver => MailReceiver}.merge(@config))
  end
  
  def fetch_mail
    logger.info "Fetching mail..."
    @fetcher.fetch
    logger.info "Fetching complete."
  end
  
end

