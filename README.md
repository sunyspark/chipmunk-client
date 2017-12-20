# Dark Blue ("Project Chipmunk")

A Preservation-Focused Dark Repository for the University of Michigan

## Running integration tests

- Make sure the validation scripts under `bin` have all required dependencies
  installed (out of scope for this respository)

- Set the `RUN_INTEGRATION` environment variable; otherwise integration tests
  are skipped.

- Run `bundle exec rspec`

## CLI / end-to-end testing

- Prerequisite: install `rsync` and set up the ability for the current user to use rsync over
  ssh to `localhost` (an ssh key is nice but not required).
- `git clone`/`bundle install` as usual
- Set up the database: `bundle exec rake db:setup`
- Set up the repository and upload paths: `bundle exec rake chipmunk:setup`
- Set up external validators in `config/validation.yml` - for a simple test try using `/bin/true`
- In another window, start the development server: `bundle exec rails server`
- In another window, start the resque pool: `bundle exec rake resque:pool`
- (Optional) Bag some audio content: `bundle exec ruby -I lib bin/makebag audio 39015012345678 /path/to/audio/material /path/to/output/bag`
- Try to upload a test bag: `bundle exec ruby -I lib bin/upload spec/support/fixtures/audio/upload/good` (or whatever bag you created before)

## Usage

### Server setup

- (Optional) Set up a mysql database and configure appropriately in `config/database.yml`
- Set the Rails secret key in `config/secrets.yml` or via `$SECRET_KEY_BASE`
- Configure storage paths
- Configure external validators (see "Validators" below)
- Start Rails (`bundle exec rails server`)
- Start resque (`bundle exec rake resque:pool`)
- Create a user (current at the rails console)
- Ensure client can connect to rails server.

### Client setup

- User should be able to connect via rsync over ssh to the configured rsync point in `config/upload.yml`
- Create `config/client.yml` as follows:

```yaml
api_key: API_KEY_FROM_USER_SETUP_ABOVE
# should be the full URL to the Chipmunk server; defaults to http://localhost:3000
url: http://localhost:3000
```

### Client usage

- `bin/upload -c path/to/config.yml /path/to/bag1 /path/to/bag2`

If no config file is specified, it will use `config/client.yml` by default.

The client will display progress on uploading and validating each bag in sequence.

## Validators

An external validator should accept as parameters:

- The external ID (i.e. a barcode or other identifier)
- The path to the bag

The validator should return zero if the bag is valid and non-zero if the bag is
not valid. Any output or errors will be captured for inspection by the client.
