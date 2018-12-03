# Bitcoinrb::Grpc

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/bitcoin/grpc`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bitcoinrb-grpc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bitcoinrb-grpc

## Usage

### Server

```
./bin/bitcoinrbd start --network=regtest
```

### Client


```ruby

stub = Bitcoin::Grpc::Blockchain::Stub.new("localhost:8080",:this_channel_is_insecure)

# Watch utxo
res = stub.watch_utxo(Bitcoin::Grpc::WatchUtxoRequest.new)
res.each {|r| puts r}

# Watch tx
tx_hash = "0f35034353babea07fd27edee27575a6f88b3786af00e195b4811e512c798171"
tx_payload = "0200000001427f57d9fb12521da329adbda27af5c03e03810ad476066a7e653a011fdbced7000000004847304402205ad2d520e37ce7a278029042bbad7c25d26addec6978a1db4e233dcb6603891f022013601c5211b836a77b02c630e17fa211e9ab1cc39b1cc003721c41b7a967a84201feffffff0200e1f5050000000016001445fcf49e1a60e8ea9ef774a0bc0839aaecf15fdd242d5a030000000016001425a2bbd8b5e1d90d061b5adbb3db283c39ebc8ab5a130000"
res = stub.watch_tx_confirmed(Bitcoin::Grpc::WatchTxConfirmedRequest.new(tx_hash:tx_hash, tx_payload: tx_payload, confirmations: 3))
res.each {|r| puts r}

# Watch token (Open Assets)
res = stub.watch_token(Bitcoin::Grpc::WatchTokenRequest.new(asset_type: ))
res.each {|r| puts r}

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/bitcoinrb-grpc. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Bitcoinrb::Grpc project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/bitcoinrb-grpc/blob/master/CODE_OF_CONDUCT.md).
