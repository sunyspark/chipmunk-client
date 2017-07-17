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
- `export CHIPMUNK_API_KEY=the generated key`
- In another window, start the development server: `bundle exec rails server`
- Create a test bag: `bundle exec bin/makebag audio 12345 /tmp/whatever` 
- Try to upload the bag: `bundle exec bin/upload /tmp/whatever`

