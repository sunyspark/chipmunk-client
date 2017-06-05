# Dark Blue ("Project Chipmunk")

A Preservation-Focused Dark Repository for the University of Michigan

## CLI / integration testing

- `git clone`/`bundle install` as usual
- Assume you have a user, e.g. `someuser` (call that `$USER`) with a home 
  directory `/home/someuser` (we'll call that `$USERHOME`)
- Set up a repository home, e.g. `/repo` (we'll call that $REPOHOME) and 
  make an incoming directory for your user: `/repo/incoming/someuser`
- Symlink `$REPOHOME/incoming/$USER` to `$USERHOME/incoming`
- Install `rsync` and set up the ability for a `$USER` to use rsync over 
  ssh to `localhost` (an ssh key is nice but not required).
- Configure `rsync_point` and `upload_path` for the dev environment in 
  `config/upload.yml`. `rsync_point` will work with the default 
  `localhost:incoming` if you followed these instructions as-is; otherwise 
  adjust as needed. Configure `upload_path` to `$REPOHOME/incoming`.
- Create a user in the rails console and note the user's returned API key.
```
bundle exec rails console dev
u = User.create(username: "$USER", email: 'somebody@wherever')
u.api_key
```

- `export CHIPMUNK_API_KEY=the generated key`
- Create a test bag: `bundle exec bin/makebag audio 12345 /tmp/whatever` 
  (currently only audio works)
- Try to upload the bag: `bundle exec bin/upload /tmp/whatever`

