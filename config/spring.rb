# frozen_string_literal: true
Spring.after_fork do
  FactoryGirl.reload if defined?(FactoryGirl)
  MessageBus.after_fork if defined?(MessageBus)
end

%w[
  .ruby-version
  .rbenv-vars
  tmp/restart.txt
  tmp/caching-dev.txt
].each { |path| Spring.watch(path) }
