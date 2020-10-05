#!/usr/bin/env rake

if ARGV[0] && ARGV[0].start_with?('test')
  ENV['RACK_ENV'] = "test"
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
end

namespace :test do
  desc "Run all tests (rake test will do this be default)"
  task :all do
    Rake::TestTask.new("all") do |t|
      t.pattern = "test/**/*_test.rb"
    end
    task("all").execute
  end

  desc "Run acceptance tests"
  task :acceptance, :file, :matcher do |task, args|
    test_task = Rake::TestTask.new("acceptance_tests") do |t|
      if args.file
        file = "test/acceptance/#{args.file}_test.rb"
        t.pattern = file
        puts "Testing #{file}"
        if args.matcher
          puts "Filters tests matching '#{args.matcher}'"
          filter = args.matcher
          if not filter.start_with? "/"
            filter = "/#{filter}/"
          end
          t.options = "--name=\"#{filter}\""
        end
      else
        t.pattern = "test/acceptance/*_test.rb"
      end
    end
    task("acceptance_tests").execute
  end

  desc "Run single file"
  task :file, :file do |task, args|
    test_task = Rake::TestTask.new("unittests") do |t|
      if args.file
        file = args.file
        unless file.start_with? "test/"
          file = "test/#{args.file}"
        end
        t.pattern = file
        puts "Testing #{file}"
      else
        t.pattern = "test/**/*_test.rb"
      end
    end
    task("unittests").execute
  end
end
