require 'color'

desc 'Run continuous integration'
task :integrate, :log do |_, args|
  if ENV['CI']
    ENV['COVERAGE'] = '1'
    ENV['PERCY_ENABLE'] = '0' # percy will be enabled just for one task
  end

  abort 'failed to run integrate:prepare' unless system('rake integrate:prepare --trace')

  tags = %w{
    @backend
    @emails
    @stats
    @search
    @no-txn
  }

  skip_directories = %w{test_helpers fixtures shoulda_macros factories}.map{|x| "test/#{x}"}

  test_dirs = Pathname.new("test").children.select(&:directory?).map(&:to_s) - skip_directories

  # Must be run in different job
  test_dirs.delete('test/remote')
  test_dirs.delete('test/performance')

  # parallel_cucumber --verbose features -o "-b -p parallel --tags=@javascript --tags=~@fakeweb --tags=~@percy" in 307.7s
  # parallel_rspec --verbose spec in 97.0s

  # parallel_test --verbose test/functional in 98.6s
  # parallel_test --verbose test/mailers test/models test/unit test/controllers test/workers test/cve test/decorators test/helpers test/proxy_helpers test/subscribers test/support test/events in 311.7s

  # parallel_test --verbose test/integration in 158.8s
  # rake doc:swagger:validate:all in 6.3s
  # rake ci:lint --trace in 7.4s
  # rake ci:jspm --trace in 15.2s
  # yarn test -- --reporters dots,junit --browsers Firefox in 10.7s
  # rake db:setup in 10.3s

  # parallel_cucumber --verbose features -o "-b -p parallel --tags=~@javascript --tags=~@backend --tags=~@emails --tags=~@stats --tags=~@search --tags=~@no-txn" in 428.6s

  # parallel_cucumber --verbose features -o "-b -p parallel --tags=~@javascript --tags=@backend,@emails,@stats,@search,@no-txn" in 410.2s

  kind = {
    '1' => [
      'parallel_cucumber --verbose features -o "-b -p parallel --tags=@javascript --tags=~@fakeweb --tags=~@percy"',
      'parallel_rspec --verbose spec',
    ],
    '2' => [
      "parallel_test --verbose #{test_dirs.delete('test/integration')}",
    ],
    '3' => [
      'rake doc:swagger:validate:all',
      'rake doc:swagger:generate:all',
      'rake ci:jspm --trace',
      'yarn test -- --reporters dots,junit --browsers Firefox',
      'yarn jest',
      'rake db:purge db:setup',
    ],
    '4' => [
      "parallel_test --verbose #{test_dirs.delete('test/functional')}",
      "parallel_test --verbose #{test_dirs.join(' ')}",
    ],
    '5' => [
      %Q{parallel_cucumber --verbose features -o "-b -p parallel --tags=~@javascript #{tags.map{|t| %Q|--tags=~#{t}| }.join(' ')}"},
    ],
    '6' => [
      %Q{parallel_cucumber --verbose features -o "-b -p parallel --tags=~@javascript --tags=#{tags.join(',')}"},
    ],

    'percy' => [
      'PERCY_ENABLE=1 cucumber -b -p parallel --tags=@percy features'
    ],
    'licenses' => [
      "export http_proxy=#{ENV['http_proxy']} https_proxy=#{ENV['https_proxy']}; rake ci:license_finder:run"
    ]
  }

  tasks = ENV['MULTIJOB_KIND'].present? ? kind.fetch(ENV['MULTIJOB_KIND']) : kind.values.flatten

  success, failure = "#{Color::GREEN}SUCCESS#{Color::CLEAR_COLOR}", "#{Color::RED}FAILURE#{Color::CLEAR_COLOR}"

  summary = []

  banner = ->(line) do
    puts
    puts "=" * 40
    puts "== #{Color::BOLD}#{line}#{Color::CLEAR}"
    puts "=" * 40
    puts

    line
  end

  require 'ci_reporter_shell'

  report = CiReporterShell.report('tmp/junit')

  junit = Dir['tmp/junit/**']

  if junit.present?
    puts 'WARNING: tmp/junit is not empty'
    puts junit
    abort 'Will not continue, tmp/junit is not empty'
  end

  total_time = 0

  results = tasks.map do |task|

    command = nil
    result = report.execute(task, env: {RAILS_ENV: Rails.env}) do |cmd|
      banner.("BEGIN: #{cmd}")
      command = cmd
    end

    summary << banner.("FINISH (#{result.success? ? success : failure}): #{command} in #{'%.1fs' % result.time}")
    total_time += result.time

    result.success?
  end

  banner.("SUMMARY: in #{'%.1fs' % total_time}\n\t#{summary.join("\n\t")}")

  abort "some tasks failed, exitting" unless results.all?

  if ENV['COVERAGE']
    FileUtils.cp(Dir["#{Dir.tmpdir}/codeclimate-test-coverage-*"],
                 Rails.root.join('tmp', 'codeclimate').tap(&:mkpath))

    system('codeclimate-batch',
           '--groups', (kind.keys.size - 1).to_s,
           '--host', 'https://cc-3scale-amend.herokuapp.com',
           '--key', ENV.fetch('BUILD_TAG'))
  end
end

namespace :integrate do

  task :prepare do
    silence_stream(STDOUT) do
      require 'system/database'
      ParallelTests::Tasks.run_in_parallel('RAILS_ENV=test rake db:drop db:create db:schema:load multitenant:triggers')
      Rake::Task['ts:configure'].invoke
    end
  end

end
