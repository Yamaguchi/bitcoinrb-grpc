require "bundler/setup"
require "bitcoin/grpc"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


def create_test_spv
  block = double('block')
  allow(block).to receive(:height).and_return(101)

  chain = double('chain')
  allow(chain).to receive(:latest_block).and_return(block)

  spv = double('spv')
  allow(spv).to receive(:chain).and_return(chain)
  allow(spv).to receive(:broadcast).and_return(nil)
  allow(spv).to receive(:add_observer).and_return(nil)
  spv
end