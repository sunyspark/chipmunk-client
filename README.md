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
- (Optional) Bag some audio content: `bundle exec ruby -I lib bin/makebag audio 39015012345678 /path/to/audio/material /path/to/output/bag`
- Try to upload a test bag: `bundle exec ruby -I lib bin/upload spec/support/fixtures/audio/upload/good` (or whatever bag you created before)

